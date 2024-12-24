import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class SFISpec: AsyncSpec {
    override static func spec() {
        describe("8.3.76 SFI") {
            describe(".parse") {
                it("parses a sentence") {

                    // MARK: Setup

                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                                fields: [2, 1,
                                         "300015", "d",
                                         "401002", "e",
                                         "901234", "m",
                                         "902345", "o",
                                         "300002", "q",
                                         "412123", "s"]),
                            createSentence(
                                delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                                fields: [2, 2,
                                         "901001", "t",
                                         "902002", "w"]),
                            createSentence(
                                delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                                fields: [1, 1,
                                         "312345", nil,
                                         "421321", "x",
                                         nil, nil,
                                         nil, nil,
                                         nil, nil])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))

                    // MARK: Message 0

                    guard let payload = (messages[2] as? Message)?.payload else {
                        fail("expected Message, got \(messages[2])")
                        return
                    }
                    guard case let .scanningFrequencies(frequencies) = payload else {
                        fail("expected .scanningFrequencies, got \(payload)")
                        return
                    }
                    expect(frequencies).to(equal([
                        .init(frequency: .MF_HF_telephone(channel: 15), mode: .F3E_G3E_simplex),
                        .init(frequency: .MF_HF_teletype(band: 1, channel: 2), mode: .F3E_G3E_duplex),
                        .init(frequency: .VHF(mode: .simplexShipTx, channel: 234), mode: .J3E),
                        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 345), mode: .H3E),
                        .init(frequency: .MF_HF_telephone(channel: 2), mode: .F1B_J2B_FEC_NBDP),
                        .init(frequency: .MF_HF_teletype(band: 12, channel: 123), mode: .F1B_J2B_ARQ_NBDP),
                        .init(frequency: .VHF(mode: .simplexShipTx, channel: 1), mode: .F1B_J2B_receive),
                        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 2), mode: .F1B_J2B)
                    ]))

                    // MARK: Message 1

                    guard let payload = (messages[4] as? Message)?.payload else {
                        fail("expected Message, got \(messages[4])")
                        return
                    }
                    guard case let .scanningFrequencies(frequencies) = payload else {
                        fail("expected .scanningFrequencies, got \(payload)")
                        return
                    }
                    expect(frequencies).to(equal([
                        .init(frequency: .MF_HF_telephone(channel: 12345), mode: nil),
                        .init(frequency: .MF_HF_teletype(band: 21, channel: 321), mode: .A1A_recorder)
                    ]))
                }

                it("throws an error for an incorrect sentence number") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                                fields: [2, 1,
                                         "300015", "d",
                                         "401002", "e",
                                         "901234", "m",
                                         "902345", "o",
                                         "300002", "q",
                                         "412123", "s"]),
                            createSentence(
                                delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                                fields: [2, 3,
                                         "901001", "t",
                                         "902002", "w"])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(3))
                    guard let error = messages[2] as? MessageError else {
                        fail("expected MessageError, got \(messages[2])")
                        return
                    }
                        expect(error.type).to(equal(.wrongSentenceNumber))
                        expect(error.fieldNumber).to(equal(1))
                }
            }

            describe(".flush") {
                it("flushes incomplete sentences") {
                    let parser = SwiftNMEA(),
                        sentence = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .scanningFrequencies,
                            fields: [2, 1,
                                     "300015", "d",
                                     "401002", "e",
                                     "901234", "m",
                                     "902345", "o",
                                     "300002", "q",
                                     "412123", "s"]),
                        data = sentence.data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .scanningFrequencies(frequencies) = message.payload else {
                        fail("expected .scanningFrequencies, got \(message)")
                        return
                    }
                    expect(frequencies).to(equal([
                        .init(frequency: .MF_HF_telephone(channel: 15), mode: .F3E_G3E_simplex),
                        .init(frequency: .MF_HF_teletype(band: 1, channel: 2), mode: .F3E_G3E_duplex),
                        .init(frequency: .VHF(mode: .simplexShipTx, channel: 234), mode: .J3E),
                        .init(frequency: .VHF(mode: .simplexCoastTx, channel: 345), mode: .H3E),
                        .init(frequency: .MF_HF_telephone(channel: 2), mode: .F1B_J2B_FEC_NBDP),
                        .init(frequency: .MF_HF_teletype(band: 12, channel: 123), mode: .F1B_J2B_ARQ_NBDP)
                    ]))
                }
            }
        }
    }
}
