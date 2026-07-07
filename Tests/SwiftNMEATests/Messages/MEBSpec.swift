import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.55 MEB")
struct MEBTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    // MEB has a large header, so a single encapsulated data field is
    // limited to 28 six-bit characters (21 bytes) to stay within the
    // 82-character sentence limit. data1 fits in one sentence; data2
    // spans two.
    let data1 = "interesting binary".data(using: .ascii)!
    let data2 = "A message spanning two MEB sentences.".data(using: .ascii)!
    let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 28)
    let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 28)

    let sentences1 = encapsulatedSentences(
      format: .broadcastCommandMessage,
      from: chunks1,
      fillBits: fillBits1,
      sequenceID: 0,
      otherFields: [0, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
    )
    let sentences2 = encapsulatedSentences(
      format: .broadcastCommandMessage,
      from: chunks2,
      fillBits: fillBits2,
      sequenceID: 1,
      otherFields: [1, 9_876_543_210, 14, 2, 1, nil, 0, "R"]
    )
    let data = (sentences1 + sentences2).joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    let payload1 = try #require((messages[1] as? Message)?.payload)
    let payload2 = try #require((messages[4] as? Message)?.payload)

    #expect(
      payload1
        == .broadcastMessage(
          sequence: 0,
          AISChannel: .noPreference,
          MMSI: 1_234_567_890,
          messageID: .addressedBinary,
          messageIndex: 3,
          broadcastBehavior: .store,
          destinationMMSI: 9_876_543_210,
          binaryStructure: .application,
          sentenceType: .command,
          data: data1
        )
    )
    #expect(
      payload2
        == .broadcastMessage(
          sequence: 1,
          AISChannel: .A,
          MMSI: 9_876_543_210,
          messageID: .broadcastSafety,
          messageIndex: 2,
          broadcastBehavior: .single,
          destinationMMSI: nil,
          binaryStructure: .unstructured,
          sentenceType: .reply,
          data: data2
        )
    )
  }

  @Test("parses a stored message with a null channel")
  func parsesAStoredMessageWithANullChannel() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "interesting binary".data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)

    // channel (field 3) is null; broadcast behaviour (field 7) is store (0)
    let sentences = encapsulatedSentences(
      format: .broadcastCommandMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [nil, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
    )
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .broadcastMessage(_, AISChannel, _, _, _, behavior, _, _, _, _) = payload
    else {
      Issue.record("expected .broadcastMessage, got \(payload)")
      return
    }

    #expect(AISChannel == nil)
    #expect(behavior == .store)
  }

  @Test("throws an error for a missing field")
  func parseThrowsAnErrorForAMissingField()
    async throws
  {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data =
      "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
      .data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .broadcastCommandMessage,
        fields: [
          2, 1, 1,
          1, nil, 1, 1, 1,
          9_876_543_210, 1, "R",
          chunks[0], fillBits
        ]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .broadcastCommandMessage,
        fields: [
          2, 2, 1,
          1, nil, 1, 1, 1,
          9_876_543_210, 1, "R",
          chunks[1], fillBits
        ]
      )
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 4)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 4)

    guard let error = messages[3] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[3])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 4)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data =
      "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
      .data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .broadcastCommandMessage,
        fields: [
          2, 1, 1,
          1, 1_234_567_890, 1, 1, 1,
          9_876_543_210, 1, "R",
          chunks[0], fillBits
        ]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .broadcastCommandMessage,
        fields: [
          2, 3, 1,
          1, 1_234_567_890, 1, 1, 1,
          9_876_543_210, 1, "R",
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

    let data =
      "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
      .data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)

    let sentences = encapsulatedSentences(
      format: .broadcastCommandMessage,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [0, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
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
      case let .broadcastMessage(
        sequence,
        AISChannel,
        MMSI,
        messageID,
        messageIndex,
        broadcastBehavior,
        destinationMMSI,
        binaryStructure,
        sentenceType,
        actualData
      ) = message.payload
    else {
      Issue.record("expected .broadcastMessage, got \(message)")
      return
    }

    #expect(sequence == 0)
    #expect(AISChannel == .noPreference)
    #expect(MMSI == 1_234_567_890)
    #expect(messageID == .addressedBinary)
    #expect(messageIndex == 3)
    #expect(broadcastBehavior == .store)
    #expect(destinationMMSI == 9_876_543_210)
    #expect(binaryStructure == .application)
    #expect(sentenceType == .command)
    #expect(actualData == "123456789012345678901".data(using: .ascii)!)
  }

  @Test("throws an error for a missing field")
  func throwsAnErrorForAMissingField() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data =
      "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
      .data(using: .ascii)!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .broadcastCommandMessage,
      fields: [
        2, 1, 1,
        1, 1_234_567_890, 1, 1, nil,
        9_876_543_210, 1, "R",
        chunks[0], fillBits
      ]
    )
    let sentenceData = sentence.data(using: .ascii)!
    let parsed = try await parser.parse(data: sentenceData)

    #expect(parsed.count == 1)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    guard let error = flushed[0] as? MessageError else {
      Issue.record("expected MessageError, got \(flushed[0])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 7)
  }
}
