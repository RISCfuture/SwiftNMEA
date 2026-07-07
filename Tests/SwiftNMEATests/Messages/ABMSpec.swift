import Testing

@testable import SwiftNMEA

@Suite("8.3.4 ABM")
struct ABMTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data1 = "This is some very interesting binary data".data(using: .ascii)!
    let data2 = "Each message must be no more than 58 characters (117 bytes)".data(
      using: .ascii
    )!
    let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 47)
    let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 47)

    let sentences1 = encapsulatedSentences(
      format: .AISBinaryMessage,
      from: chunks1,
      fillBits: fillBits1,
      sequenceID: 0,
      otherFields: [123_456_789, 0, "01"]
    )
    let sentences2 = encapsulatedSentences(
      format: .AISBinaryMessage,
      from: chunks2,
      fillBits: fillBits2,
      sequenceID: 1,
      otherFields: [987_654_321, 0, "02"]
    )
    let data = (sentences1 + sentences2).joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 6)
    let payload1 = try #require((messages[2] as? Message)?.payload)
    let payload2 = try #require((messages[5] as? Message)?.payload)
    #expect(
      payload1
        == .AISBinaryMessage(
          sequentialIdentifier: 0,
          MMSI: 123_456_789,
          channel: .noPreference,
          messageID: .positionReportSOTDMA,
          data: data1
        )
    )
    #expect(
      payload2
        == .AISBinaryMessage(
          sequentialIdentifier: 1,
          MMSI: 987_654_321,
          channel: .noPreference,
          messageID: .positionReportSOTDMA_2,
          data: data2
        )
    )
  }

  @Test("throws an error for missing fields")
  func parseThrowsAnErrorForMissingFields() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "This is some very interesting binary data".data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 47)
    let sentences = encapsulatedSentences(
      format: .AISBinaryMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [nil, 0, "01"]
    )
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 4)

    guard let error = messages[1] as? MessageError
    else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 3)

    guard let error = messages[3] as? MessageError
    else {
      Issue.record("expected MessageError, got \(messages[3])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 3)
  }

  @Test("throws an error for a wrong sentence number")
  func throwsAnErrorForAWrongSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "Each message must be no more than 58 characters (117 bytes)".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 47)
    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBinaryMessage,
        fields: [
          2, 1, 1,
          1_234_567_890, 1, 1,
          chunks[0], fillBits
        ]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .AISBinaryMessage,
        fields: [
          2, 1, 1,
          1_234_567_890, 1, 1,
          chunks[1], fillBits
        ]
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

    let data = "1234567890123456789012345678901234567890123456789012345678901234567890".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 47)

    let sentences = encapsulatedSentences(
      format: .AISBinaryMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [123_456_789, 0, "01"]
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
    guard
      case let .AISBinaryMessage(
        sequentialIdentifier,
        MMSI,
        channel,
        messageID,
        actualData
      ) =
        message.payload
    else {
      Issue.record("expected .AISBinaryMessage, got \(message)")
      return
    }

    #expect(sequentialIdentifier == 0)
    #expect(MMSI == 123_456_789)
    #expect(channel == .noPreference)
    #expect(messageID == .positionReportSOTDMA)
    #expect(actualData == "1234567890123456789012345678901234".data(using: .ascii)!)
  }

  @Test("throws an error for missing fields")
  func flushThrowsAnErrorForMissingFields() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "1234567890123456789012345678901234567890123456789012345678901234567890".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 47)

    let sentences = encapsulatedSentences(
      format: .AISBinaryMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [123_456_789, 0, "01"]
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
    guard
      case let .AISBinaryMessage(
        sequentialIdentifier,
        MMSI,
        channel,
        messageID,
        actualData
      ) =
        message.payload
    else {
      Issue.record("expected .AISBinaryMessage, got \(message)")
      return
    }

    #expect(sequentialIdentifier == 0)
    #expect(MMSI == 123_456_789)
    #expect(channel == .noPreference)
    #expect(messageID == .positionReportSOTDMA)
    #expect(actualData == "1234567890123456789012345678901234".data(using: .ascii)!)
  }
}
