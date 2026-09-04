import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.110 TXT` {
  // MARK: - .parse, example from the spec

  @Test
  func `parses the example`() async throws {
    let parser = SwiftNMEA()
    let sentence = "$GPTXT,01,01,25,DR MODE-ANTENNA FAULT^21*38\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    #expect(payload == .text("DR MODE-ANTENNA FAULT!", identifier: 25))
  }

  @Test
  func `throws an error for an incorrect sentence number`() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "$GPTXT,02,01,25,DR MODE-ANTENNA FAULT^21"),
      applyChecksum(to: "$GPTXT,02,03,25,DR MODE-ANTENNA FAULT^21")
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .parse, STA8089FG

  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = "$GPTXT,(C)2000-2018 ST Microelectronics*29\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    #expect(payload == .text("(C)2000-2018 ST Microelectronics", identifier: nil))
  }

  // MARK: - .flush

  @Test
  func `flushes incomplete messages`() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .text,
        fields: [3, 1, 24, "FIRST PART OF MESSAGE "]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .text,
        fields: [3, 2, nil, "SECOND PART OF MESSAGE"]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 2)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    #expect(
      message.payload == .text("FIRST PART OF MESSAGE SECOND PART OF MESSAGE", identifier: 24)
    )
  }
}
