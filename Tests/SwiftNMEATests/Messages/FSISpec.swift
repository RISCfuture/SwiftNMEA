import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.37 FSI` {
  @Test(arguments: SpecExample.all)
  func `parses an example from the spec`(_ example: SpecExample) async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: example.sentence)
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    #expect(message.payload == example.payload)
  }

  /// One of the lettered `FSI` examples from §8.3.37 of the spec.
  struct SpecExample: Sendable, CustomTestStringConvertible {
    static let all: [Self] = [
      .init(
        letter: "a",
        sentence: "$CTFSI,020230,026140,m,0,C",
        payload: .frequencySetInfo(
          transmit: .MF_HF(frequency: .init(value: 2023, unit: .kilohertz)),
          receive: .MF_HF(frequency: .init(value: 2614, unit: .kilohertz)),
          mode: .J3E,
          powerLevel: 0,
          type: .command
        )
      ),
      .init(
        letter: "b",
        sentence: "$CTFSI,020230,026140,m,5,R",
        payload: .frequencySetInfo(
          transmit: .MF_HF(frequency: .init(value: 2023, unit: .kilohertz)),
          receive: .MF_HF(frequency: .init(value: 2614, unit: .kilohertz)),
          mode: .J3E,
          powerLevel: 5,
          type: .reply
        )
      ),
      .init(
        letter: "c",
        sentence: "$CTFSI,,021820,o,,C",
        payload: .frequencySetInfo(
          transmit: nil,
          receive: .MF_HF(frequency: .init(value: 2182, unit: .kilohertz)),
          mode: .H3E,
          powerLevel: nil,
          type: .command
        )
      ),
      .init(
        letter: "d",
        sentence: "$CDFSI,900016,,d,9,R",
        payload: .frequencySetInfo(
          transmit: .VHF(mode: .standard, channel: 16),
          receive: nil,
          mode: .F3E_G3E_simplex,
          powerLevel: 9,
          type: .reply
        )
      ),
      .init(
        letter: "e",
        sentence: "$CTFSI,300821,,m,9,C",
        payload: .frequencySetInfo(
          transmit: .MF_HF_telephone(channel: 821),
          receive: nil,
          mode: .J3E,
          powerLevel: 9,
          type: .command
        )
      ),
      .init(
        letter: "f",
        sentence: "$CTFSI,404001,,w,5,R",
        payload: .frequencySetInfo(
          transmit: .MF_HF_teletype(band: 4, channel: 1),
          receive: nil,
          mode: .F1B_J2B,
          powerLevel: 5,
          type: .reply
        )
      ),
      .init(
        letter: "g",
        sentence: "$CTFSI,416193,,s,0,C",
        payload: .frequencySetInfo(
          transmit: .MF_HF_teletype(band: 16, channel: 193),
          receive: nil,
          mode: .F1B_J2B_ARQ_NBDP,
          powerLevel: 0,
          type: .command
        )
      ),
      .init(
        letter: "h",
        sentence: "$CTFSI,041620,043020,|,9,R",
        payload: .frequencySetInfo(
          transmit: .MF_HF(frequency: .init(value: 4162, unit: .kilohertz)),
          receive: .MF_HF(frequency: .init(value: 4302, unit: .kilohertz)),
          mode: .F1C_F2C_F3C,
          powerLevel: 9,
          type: .reply
        )
      ),
      .init(
        letter: "i",
        sentence: "$CXFSI,,021875,t,,C",
        payload: .frequencySetInfo(
          transmit: nil,
          receive: .MF_HF(frequency: .init(value: 2187.5, unit: .kilohertz)),
          mode: .F1B_J2B_receive,
          powerLevel: nil,
          type: .command
        )
      )
    ]

    let letter: Character
    let sentence: String
    let payload: Message.Payload

    var testDescription: String { "example (\(letter)): \(sentence)" }
  }
}
