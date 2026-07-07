import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.18 BBM")
struct BBMTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data1 = "This is some very interesting binary data".data(using: .ascii)!
    let data2 =
      "Each message must be no more than 60 characters (117 bytes) -- this one is longer"
      .data(using: .ascii)!
    let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 57)
    let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 57)

    let sentences1 = encapsulatedSentences(
      format: .AISBroadcastBinaryMessage,
      from: chunks1,
      fillBits: fillBits1,
      sequenceID: 0,
      otherFields: [0, "01"]
    )
    let sentences2 = encapsulatedSentences(
      format: .AISBroadcastBinaryMessage,
      from: chunks2,
      fillBits: fillBits2,
      sequenceID: 1,
      otherFields: [0, "02"]
    )
    let data = (sentences1 + sentences2).joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    let payload1 = try #require((messages[1] as? Message)?.payload)
    let payload2 = try #require((messages[4] as? Message)?.payload)
    #expect(
      payload1
        == .AISBroadcastBinaryMessage(
          sequentialIdentifier: 0,
          channel: .noPreference,
          messageID: .positionReportSOTDMA,
          data: data1
        )
    )
    #expect(
      payload2
        == .AISBroadcastBinaryMessage(
          sequentialIdentifier: 1,
          channel: .noPreference,
          messageID: .positionReportSOTDMA_2,
          data: data2
        )
    )
  }

  @Test("throws an error for missing fields")
  func throwsAnErrorForMissingFields() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "Each message must be no more than 58 characters (117 bytes)".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 57)

    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBroadcastBinaryMessage,
        fields: [2, 1, 1, nil, 1, chunks[0], fillBits]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBroadcastBinaryMessage,
        fields: [2, 2, 1, nil, 1, chunks[0], fillBits]
      )
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 4)

    let error1 = try #require(messages[1] as? MessageError)
    #expect(error1.type == .missingRequiredValue)
    #expect(error1.fieldNumber == 3)

    let error2 = try #require(messages[3] as? MessageError)
    #expect(error2.type == .missingRequiredValue)
    #expect(error2.fieldNumber == 3)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "Each message must be no more than 58 characters (117 bytes)".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 57)

    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBroadcastBinaryMessage,
        fields: [2, 1, 1, 1, 1, chunks[0], fillBits]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBroadcastBinaryMessage,
        fields: [2, 3, 1, 1, 1, chunks[1], fillBits]
      )
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "1234567890123456789012345678901234567890123456789012345678901234567890".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 57)

    let sentences = encapsulatedSentences(
      format: .AISBroadcastBinaryMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [0, "01"]
    )
    let sentenceData = sentences[0].data(using: .ascii)!

    let parsed = try await parser.parse(data: sentenceData)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    guard
      case let .AISBroadcastBinaryMessage(
        sequentialIdentifier,
        channel,
        messageID,
        actualData
      ) = message
        .payload
    else {
      Issue.record("expected .AISBroadcastBinaryMessage, got \(message)")
      return
    }

    #expect(sequentialIdentifier == 0)
    #expect(channel == .noPreference)
    #expect(messageID == .positionReportSOTDMA)
    #expect(actualData == "123456789012345678901234567890123456789012".data(using: .ascii)!)
  }
}
