import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.109 TUT")
struct TUTTests {
  // MARK: - .parse

  @Test("parses the proprietary example from the spec")
  func parsesTheProprietaryExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$SDTUT,SD,01,01,1,PXYZ,02*6D\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .multiLanguageText(source, text, data, translationCode) = payload
    else {
      Issue.record("expected .multiLanguageText, got \(payload)")
      return
    }

    #expect(source == .depthSounder)
    #expect(text == nil)
    #expect(data.count == 1)
    #expect(data[0] == 0x02)
    #expect(translationCode == "PXYZ")
  }

  @Test("parses the Unicode example from the spec")
  func parsesTheUnicodeExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = "$INTUT,SD,01,01,1,U,6D45702C5371967A*5D\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .multiLanguageText(source, text, _, translationCode) = payload
    else {
      Issue.record("expected .multiLanguageText, got \(payload)")
      return
    }

    #expect(source == .depthSounder)
    #expect(text == "浅瀬危険")
    #expect(translationCode == "U")
  }

  @Test("parses the ASCII example from the spec")
  func parsesTheASCIIExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = "$INTUT,SD,01,01,1,A,5368616C6C6F7720576174657221*4B\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .multiLanguageText(source, text, _, translationCode) = payload
    else {
      Issue.record("expected .multiLanguageText, got \(payload)")
      return
    }

    #expect(source == .depthSounder)
    #expect(text == "Shallow Water!")
    #expect(translationCode == "A")
  }

  @Test("throws an error for invalid encoded data")
  func parseThrowsAnErrorForInvalidEncodedData() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .multiLanguageText,
      // invalid high-bit characters
      fields: [
        "SD", "01", "01", 1, "A",
        "not a valid hex string!"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 5)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "01", 1, "A", "5368616C6C6F7720"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "04", 1, "A", "576174657221"]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes incomplete messages")
  func flushesIncompleteMessages() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "01", 1, "A", "5368616C6C6F7720"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "02", 1, "A", "576174657221"]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let parsed = try await parser.parse(data: data)

    #expect(parsed.count == 2)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    guard
      case let .multiLanguageText(source, text, _, translationCode) = message.payload
    else {
      Issue.record("expected .multiLanguageText, got \(message)")
      return
    }

    #expect(source == .depthSounder)
    #expect(text == "Shallow Water!")
    #expect(translationCode == "A")
  }

  @Test("throws an error for invalid encoded data")
  func flushThrowsAnErrorForInvalidEncodedData() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "01", 1, "A", "not a valid hex string!"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .multiLanguageText,
        fields: ["SD", "03", "02", 1, "A", "576174657221"]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    _ = try await parser.parse(data: data)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    let error = try #require(flushed[0] as? MessageError)
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 5)
  }
}
