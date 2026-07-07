import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.115 VDO")
struct VDOTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data1 = "This is some very interesting binary data".data(using: .ascii)!
    let data2 = "Each message must be no more than 60 characters to fit in a single sentence"
      .data(using: .ascii)!
    let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 60)
    let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 60)

    let sentences1 = encapsulatedSentences(
      format: .VDLOwnshipReport,
      from: chunks1,
      fillBits: fillBits1,
      sequenceID: 0,
      otherFields: ["A"]
    )
    let sentences2 = encapsulatedSentences(
      format: .VDLOwnshipReport,
      from: chunks2,
      fillBits: fillBits2,
      sequenceID: 1,
      otherFields: ["B"]
    )
    let data = (sentences1 + sentences2).joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    let payload1 = try #require((messages[1] as? Message)?.payload)
    let payload2 = try #require((messages[4] as? Message)?.payload)
    #expect(payload1 == .VDLOwnshipReport(data1, channel: .A))
    #expect(payload2 == .VDLOwnshipReport(data2, channel: .B))
  }

  @Test("parses a 62-character (46-byte) sentence when some fields are nil")
  func parsesA62CharacterSentenceWhenSomeFieldsAreNil() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "1234567890123456789012345678901234567890123456".data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 62)
    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .VDLOwnshipReport,
      fields: [1, 1, nil, nil, chunks[0], fillBits]
    )
    let sentenceData = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .VDLOwnshipReport(actualData, channel) = payload else {
      Issue.record("expected .VDLOwnshipReport, got \(payload)")
      return
    }
    #expect(actualData == data)
    #expect(channel == nil)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "This data is exactly 62 characters long. This data is exactly ".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)
    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .VDLOwnshipReport,
        fields: [2, 1, nil, nil, chunks[0], fillBits]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .VDLOwnshipReport,
        fields: [2, 3, nil, nil, chunks[1], fillBits]
      )
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 3)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "1234567890123456789012345678901234567890123456789012".data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)

    let sentences = encapsulatedSentences(
      format: .VDLOwnshipReport,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: ["A"]
    )
    let sentenceData = sentences[0].data(using: .ascii)!

    let parsed = try await parser.parse(data: sentenceData)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    guard let message = messages[0] as? Message else {
      Issue.record("expected Message, got \(messages[0])")
      return
    }
    guard case let .VDLOwnshipReport(message, channel) = message.payload else {
      Issue.record("expected .VDLMessage, got \(message)")
      return
    }

    #expect(channel == .A)
    #expect(message == "12345678901234567890123456789012345678901234".data(using: .ascii)!)
  }
}
