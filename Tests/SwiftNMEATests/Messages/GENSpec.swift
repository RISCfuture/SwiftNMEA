import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GENSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.40 GEN") {
      it("parses the example in the spec") {
        let parser = SwiftNMEA()
        let sentences = [
          "$VRGEN,0000,011200.00,0123,4567,89AB,CDEF,0123,4567,89AB,CDEF*64\r\n",
          "$VRGEN,0008,011200.00,0123,4567*6C\r\n"
        ]
        let data = sentences.joined().data(using: .ascii)!
        let parsed = try await parser.parse(data: data)
        let flushed = try await parser.flush(includeIncomplete: true)

        expect(parsed).to(haveCount(2))
        expect(flushed).to(haveCount(1))

        guard let message = flushed[0] as? Message else {
          fail("expected Message, got \(flushed[0])")
          return
        }
        guard case let .genericBinary(time, entities) = message.payload else {
          fail("expected .genericBinary, got \(message)")
          return
        }

        let components = Calendar.current.dateComponents(in: .gmt, from: time!)
        expect(components.hour).to(equal(1))
        expect(components.minute).to(equal(12))
        expect(components.second).to(equal(0))
        expect(components.nanosecond).to(equal(0))

        // 10 contiguous 16-bit entities at indices 0…9, no gaps
        expect(entities).to(haveCount(10))
        let contiguous = entities.sorted { $0.key < $1.key }.map(\.value).reduce(Data(), +)
        expect(contiguous.hex).to(equal("0123456789ABCDEF0123456789ABCDEF01234567"))
      }

      it("represents an interior null field as a gap") {
        let parser = SwiftNMEA()
        // entity at index 1 is null (no update); 0, 2, and 3 are present
        let sentence = "$VRGEN,0000,011200.00,0123,,89AB,CDEF*"
        let withChecksum = appendChecksum(to: sentence)
        let data = withChecksum.data(using: .ascii)!
        _ = try await parser.parse(data: data)
        let flushed = try await parser.flush(includeIncomplete: true)

        expect(flushed).to(haveCount(1))
        guard let message = flushed[0] as? Message,
          case let .genericBinary(_, entities) = message.payload
        else {
          fail("expected .genericBinary, got \(flushed[0])")
          return
        }

        // the null field leaves index 1 absent while the others keep their index
        expect(entities).to(haveCount(3))
        expect(entities[0]?.hex).to(equal("0123"))
        expect(entities[1]).to(beNil())
        expect(entities[2]?.hex).to(equal("89AB"))
        expect(entities[3]?.hex).to(equal("CDEF"))
      }

      it("reports an error for a malformed (present but non-HEX) field") {
        let parser = SwiftNMEA()
        let sentence = "$VRGEN,0000,011200.00,0123,XYZW,89AB*"
        let withChecksum = appendChecksum(to: sentence)
        let data = withChecksum.data(using: .ascii)!
        let parsed = try await parser.parse(data: data)

        guard let error = parsed.compactMap({ $0 as? MessageError }).first else {
          fail("expected MessageError, got \(parsed)")
          return
        }
        expect(error.type).to(equal(.badNumericValue))
        expect(error.fieldNumber).to(equal(3))  // the XYZW field
      }
    }
  }

  private static func appendChecksum(to sentence: String) -> String {
    precondition(sentence.hasPrefix("$") && sentence.hasSuffix("*"))
    let body = sentence.dropFirst().dropLast()
    let checksum = body.utf8.reduce(UInt8(0)) { $0 ^ $1 }
    return sentence + String(format: "%02X", checksum) + "\r\n"
  }
}
