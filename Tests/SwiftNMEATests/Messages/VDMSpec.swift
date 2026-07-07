import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.114 VDM")
struct VDMTests {
  private static let VDLData: Data = {
    let VDLBinaryData = """
      000001
      100000
      000000
      000000
      000000
      011111
      110000
      000001
      011001
      100100
      000001
      111011
      111110
      100100
      100000
      000010
      111010
      001010
      000100
      000011
      101111
      111010
      111111
      101010
      000000
      000101
      111001
      000100
      """
    let VDLBytes =
      VDLBinaryData
      .replacing(.newlineSequence, with: "")
      .chunks(ofCount: 8)
      .map { UInt8($0, radix: 2)! }
    return Data(VDLBytes)
  }()

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
      format: .VDLMessage,
      from: chunks1,
      fillBits: fillBits1,
      sequenceID: 0,
      otherFields: ["A"]
    )
    let sentences2 = encapsulatedSentences(
      format: .VDLMessage,
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
    #expect(payload1 == .VDLMessage(data1, channel: .A))
    #expect(payload2 == .VDLMessage(data2, channel: .B))
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
      format: .VDLMessage,
      fields: [1, 1, nil, nil, chunks[0], fillBits]
    )
    let sentenceData = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .VDLMessage(actualData, channel) = payload else {
      Issue.record("expected .VDLMessage, got \(payload)")
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
        format: .VDLMessage,
        fields: [2, 1, nil, nil, chunks[0], fillBits]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .VDLMessage,
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

  @Test("parses the first example from the spec")
  func parsesTheFirstExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "!AIVDM,1,1,,A,1P000Oh1IT1svTP2r:43grwb05q4,0")
    let sentenceData = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .VDLMessage(Self.VDLData, channel: .A))
  }

  @Test("parses the second example from the spec")
  func parsesTheSecondExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "!AIVDM,2,1,7,A,1P000Oh1IT1svT,0"),
      applyChecksum(to: "!AIVDM,2,2,7,A,P2r:43grwb05q4,0")
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    #expect(payload == .VDLMessage(Self.VDLData, channel: .A))
  }

  @Test("parses the third example from the spec")
  func parsesTheThirdExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "!AIVDM,2,1,9,A,1P000Oh1IT1svTP2r:43,0"),
      applyChecksum(to: "!AIVDM,2,2,9,A,grwb05q4,0")
    ]
    let sentenceData = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: sentenceData)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    #expect(payload == .VDLMessage(Self.VDLData, channel: .A))
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let data = "12345678901234567890123456789012345678901234567890123456789012".data(
      using: .ascii
    )!
    let (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)

    let sentences = encapsulatedSentences(
      format: .VDLMessage,
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
    guard case let .VDLMessage(message, channel) = message.payload else {
      Issue.record("expected .VDLMessage, got \(message)")
      return
    }

    #expect(channel == .A)
    #expect(message == "12345678901234567890123456789012345678901234".data(using: .ascii)!)
  }
}
