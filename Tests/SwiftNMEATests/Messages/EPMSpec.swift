import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.32 EPM")
struct EPMTests {
  // MARK: - .parse

  @Test("parses a multi-sentence command and concatenates the value")
  func parsesAMultiSentenceCommandAndConcatenatesTheValue() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .ECDIS,
        format: .equipmentPropertyLong,
        fields: [
          2, 1, 98, "C", "AI", "503123450", 1234, "This-is-an-example-of-a-long-parameter"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .ECDIS,
        format: .equipmentPropertyLong,
        fields: [
          2, 2, 98, "C", "AI", "503123450", 1234, "-which-continues-over-multiple-messages"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    guard
      case let .equipmentPropertyLong(type, reference, property, value) = payload
    else {
      Issue.record("expected .equipmentPropertyLong, got \(payload)")
      return
    }

    #expect(type == .command)
    #expect(reference.type == .automaticID)
    #expect(reference.uniqueID == "503123450")
    #expect(property.rawValue == 1234)
    #expect(
      value == "This-is-an-example-of-a-long-parameter-which-continues-over-multiple-messages"
    )
  }

  @Test("decodes escaped reserved characters in the value")
  func decodesEscapedReservedCharactersInTheValue() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentPropertyLong,
      fields: [1, 1, 25, "R", "AI", "503123450", 101, "a^2Cb"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .equipmentPropertyLong(type, _, _, value) = payload else {
      Issue.record("expected .equipmentPropertyLong, got \(payload)")
      return
    }

    #expect(type == .reply)
    #expect(value == "a,b")
  }

  @Test("parses a null unique identifier")
  func parsesANullUniqueIdentifier() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentPropertyLong,
      fields: [1, 1, 12, "C", "AI", nil, 7, "value"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .equipmentPropertyLong(_, reference, _, _) = payload else {
      Issue.record("expected .equipmentPropertyLong, got \(payload)")
      return
    }

    #expect(reference.uniqueID == nil)
  }

  @Test("throws an error for a negative property identifier")
  func throwsAnErrorForANegativePropertyIdentifier() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentPropertyLong,
      fields: [1, 1, 12, "C", "AI", "503123450", -5, "value"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
    #expect(error.fieldNumber == 6)
  }

  @Test("rejects an out-of-order sentence instead of concatenating it")
  func rejectsAnOutOfOrderSentenceInsteadOfConcatenatingIt() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .ECDIS,
        format: .equipmentPropertyLong,
        fields: [3, 1, 98, "C", "AI", "503123450", 1234, "first-"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .ECDIS,
        format: .equipmentPropertyLong,
        fields: [3, 3, 98, "C", "AI", "503123450", 1234, "third"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .ECDIS,
        format: .equipmentPropertyLong,
        fields: [3, 2, 98, "C", "AI", "503123450", 1234, "second-"]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // Sentence 3 appends after sentence 1; sentence 2 then arrives out of
    // order. It must be rejected rather than concatenated in the wrong
    // position (which would silently corrupt the reassembled value).
    guard let error = messages.last as? MessageError else {
      Issue.record("expected MessageError, got \(messages.last as Any)")
      return
    }
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes an incomplete message")
  func flushesAnIncompleteMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentPropertyLong,
      fields: [2, 1, 98, "C", "AI", "503123450", 1234, "first-half"]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    guard let message = flushed[0] as? Message else {
      Issue.record("expected Message, got \(flushed[0])")
      return
    }
    guard case let .equipmentPropertyLong(_, _, _, value) = message.payload else {
      Issue.record("expected .equipmentPropertyLong, got \(message.payload)")
      return
    }
    #expect(value == "first-half")
  }
}
