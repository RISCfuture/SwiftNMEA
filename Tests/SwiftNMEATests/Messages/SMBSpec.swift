import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.96 SMB")
struct SMBTests {
  // MARK: - .parse

  @Test("parses a multi-sentence message and decodes code delimiters")
  func parsesAMultiSentenceMessageAndDecodesCodeDelimiters() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "$CSSMB,002,001,0,123456,FROM:MRCC^0D^0A"),
      applyChecksum(to: "$CSSMB,002,002,0,123456,TO:ALL SHIPS")
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // two echoed sentences, then the assembled message on the last sentence
    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    #expect(
      payload
        == .safetyNETMessageBody(
          "FROM:MRCC\r\nTO:ALL SHIPS",
          uniqueMessageNumber: 123_456,
          identifier: 0
        )
    )
  }

  @Test("parses a single sentence with null sentence number and identifier")
  func parsesASingleSentenceWithNullSentenceNumberAndIdentifier() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETMessageBody,
      fields: ["001", nil, nil, 654_321, "SINGLE LINE MESSAGE"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .safetyNETMessageBody(
          "SINGLE LINE MESSAGE",
          uniqueMessageNumber: 654_321,
          identifier: nil
        )
    )
  }

  @Test("throws an error for an out-of-range sentence number")
  func throwsAnErrorForAnOutOfRangeSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "$CSSMB,002,001,0,123456,FIRST"),
      applyChecksum(to: "$CSSMB,002,003,0,123456,THIRD")
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  @Test("throws an error for a null sentence number in a multi-sentence message")
  func throwsAnErrorForANullSentenceNumberInAMultiSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETMessageBody,
      fields: ["002", nil, 0, 123_456, "FIRST"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes an incomplete message")
  func flushesAnIncompleteMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETMessageBody,
      fields: ["003", "001", 5, 222_333, "PARTIAL BODY"]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    #expect(
      message.payload
        == .safetyNETMessageBody(
          "PARTIAL BODY",
          uniqueMessageNumber: 222_333,
          identifier: 5
        )
    )
  }
}
