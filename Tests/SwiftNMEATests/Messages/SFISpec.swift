import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.90 SFI")
struct SFITests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {

    // MARK: Setup

    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commVHF,
        format: .scanningFrequencies,
        fields: [
          2, 1,
          "300015", "d",
          "401002", "e",
          "901234", "m",
          "902345", "o",
          "300002", "q",
          "412123", "s"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commVHF,
        format: .scanningFrequencies,
        fields: [
          2, 2,
          "901001", "t",
          "902002", "w"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commVHF,
        format: .scanningFrequencies,
        fields: [
          1, 1,
          "312345", nil,
          "421321", "x",
          nil, nil,
          nil, nil,
          nil, nil
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)

    // MARK: Message 0

    guard let payload = (messages[2] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[2])")
      return
    }
    guard case .scanningFrequencies(let frequencies) = payload else {
      Issue.record("expected .scanningFrequencies, got \(payload)")
      return
    }
    #expect(
      frequencies == [
        .init(frequency: .MF_HF_telephone(channel: 15), mode: .F3E_G3E_simplex),
        .init(frequency: .MF_HF_teletype(band: 1, channel: 2), mode: .F3E_G3E_duplex),
        .init(frequency: .VHF(mode: .simplexShipTx, channel: 234), mode: .J3E),
        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 345), mode: .H3E),
        .init(frequency: .MF_HF_telephone(channel: 2), mode: .F1B_J2B_FEC_NBDP),
        .init(frequency: .MF_HF_teletype(band: 12, channel: 123), mode: .F1B_J2B_ARQ_NBDP),
        .init(frequency: .VHF(mode: .simplexShipTx, channel: 1), mode: .F1B_J2B_receive),
        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 2), mode: .F1B_J2B)
      ]
    )

    // MARK: Message 1

    guard let payload = (messages[4] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[4])")
      return
    }
    guard case .scanningFrequencies(let frequencies) = payload else {
      Issue.record("expected .scanningFrequencies, got \(payload)")
      return
    }
    #expect(
      frequencies == [
        .init(frequency: .MF_HF_telephone(channel: 12345), mode: nil),
        .init(frequency: .MF_HF_teletype(band: 21, channel: 321), mode: .A1A_recorder)
      ]
    )
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commVHF,
        format: .scanningFrequencies,
        fields: [
          2, 1,
          "300015", "d",
          "401002", "e",
          "901234", "m",
          "902345", "o",
          "300002", "q",
          "412123", "s"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commVHF,
        format: .scanningFrequencies,
        fields: [
          2, 3,
          "901001", "t",
          "902002", "w"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

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
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .scanningFrequencies,
      fields: [
        2, 1,
        "300015", "d",
        "401002", "e",
        "901234", "m",
        "902345", "o",
        "300002", "q",
        "412123", "s"
      ]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    guard let message = messages[0] as? Message else {
      Issue.record("expected Message, got \(messages[0])")
      return
    }
    guard case .scanningFrequencies(let frequencies) = message.payload else {
      Issue.record("expected .scanningFrequencies, got \(message)")
      return
    }
    #expect(
      frequencies == [
        .init(frequency: .MF_HF_telephone(channel: 15), mode: .F3E_G3E_simplex),
        .init(frequency: .MF_HF_teletype(band: 1, channel: 2), mode: .F3E_G3E_duplex),
        .init(frequency: .VHF(mode: .simplexShipTx, channel: 234), mode: .J3E),
        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 345), mode: .H3E),
        .init(frequency: .MF_HF_telephone(channel: 2), mode: .F1B_J2B_FEC_NBDP),
        .init(frequency: .MF_HF_teletype(band: 12, channel: 123), mode: .F1B_J2B_ARQ_NBDP)
      ]
    )
  }
}
