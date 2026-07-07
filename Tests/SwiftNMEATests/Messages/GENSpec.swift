import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.40 GEN")
struct GENTests {
  private static func appendChecksum(to sentence: String) -> String {
    precondition(sentence.hasPrefix("$") && sentence.hasSuffix("*"))
    let body = sentence.dropFirst().dropLast()
    let checksum = body.utf8.reduce(UInt8(0)) { $0 ^ $1 }
    return sentence + String(format: "%02X", checksum) + "\r\n"
  }

  @Test("parses the example in the spec")
  func parsesTheExampleInTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      "$VRGEN,0000,011200.00,0123,4567,89AB,CDEF,0123,4567,89AB,CDEF*64\r\n",
      "$VRGEN,0008,011200.00,0123,4567*6C\r\n"
    ]
    let data = sentences.joined().data(using: .ascii)!
    let parsed = try await parser.parse(data: data)
    let flushed = try await parser.flush(includeIncomplete: true)

    #expect(parsed.count == 2)
    #expect(flushed.count == 1)

    guard let message = flushed[0] as? Message else {
      Issue.record("expected Message, got \(flushed[0])")
      return
    }
    guard case let .genericBinary(time, entities) = message.payload else {
      Issue.record("expected .genericBinary, got \(message)")
      return
    }

    let components = Calendar.current.dateComponents(in: .gmt, from: time!)
    #expect(components.hour == 1)
    #expect(components.minute == 12)
    #expect(components.second == 0)
    #expect(components.nanosecond == 0)

    // 10 contiguous 16-bit entities at indices 0…9, no gaps
    #expect(entities.count == 10)
    let contiguous = entities.sorted { $0.key < $1.key }.map(\.value).reduce(Data(), +)
    #expect(contiguous.hex == "0123456789ABCDEF0123456789ABCDEF01234567")
  }

  @Test("represents an interior null field as a gap")
  func representsAnInteriorNullFieldAsAGap() async throws {
    let parser = SwiftNMEA()
    // entity at index 1 is null (no update); 0, 2, and 3 are present
    let sentence = "$VRGEN,0000,011200.00,0123,,89AB,CDEF*"
    let withChecksum = Self.appendChecksum(to: sentence)
    let data = withChecksum.data(using: .ascii)!
    _ = try await parser.parse(data: data)
    let flushed = try await parser.flush(includeIncomplete: true)

    #expect(flushed.count == 1)
    guard let message = flushed[0] as? Message,
      case let .genericBinary(_, entities) = message.payload
    else {
      Issue.record("expected .genericBinary, got \(flushed[0])")
      return
    }

    // the null field leaves index 1 absent while the others keep their index
    #expect(entities.count == 3)
    #expect(entities[0]?.hex == "0123")
    #expect(entities[1] == nil)
    #expect(entities[2]?.hex == "89AB")
    #expect(entities[3]?.hex == "CDEF")
  }

  @Test("reports an error for a malformed (present but non-HEX) field")
  func reportsAnErrorForAMalformedField() async throws {
    let parser = SwiftNMEA()
    let sentence = "$VRGEN,0000,011200.00,0123,XYZW,89AB*"
    let withChecksum = Self.appendChecksum(to: sentence)
    let data = withChecksum.data(using: .ascii)!
    let parsed = try await parser.parse(data: data)

    guard let error = parsed.compactMap({ $0 as? MessageError }).first else {
      Issue.record("expected MessageError, got \(parsed)")
      return
    }
    #expect(error.type == .badNumericValue)
    #expect(error.fieldNumber == 3)  // the XYZW field
  }
}
