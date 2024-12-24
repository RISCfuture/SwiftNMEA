import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class TXTSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.87 TXT") {
            describe(".parse") {
                context("example from the spec") {
                    it("parses the example") {
                        let parser = SwiftNMEA(),
                            sentence = "$GPTXT,01,01,25,DR MODE-ANTENNA FAULT^21*38\r\n",
                            data = sentence.data(using: .ascii)!,
                            messages = try await parser.parse(data: data)

                        expect(messages).to(haveCount(2))
                        guard let payload = (messages[1] as? Message)?.payload else {
                            fail("expected Message, got \(messages[1])")
                            return
                        }

                        expect(payload).to(equal(.text("DR MODE-ANTENNA FAULT!", identifier: 25)))
                    }

                    it("throws an error for an incorrect sentence number") {
                        let parser = SwiftNMEA(),
                            sentences = [
                                applyChecksum(to: "$GPTXT,02,01,25,DR MODE-ANTENNA FAULT^21"),
                                applyChecksum(to: "$GPTXT,02,03,25,DR MODE-ANTENNA FAULT^21")
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

                context("STA8089FG") {
                    it("parses a sentence") {
                        let parser = SwiftNMEA(),
                            sentence = "$GPTXT,(C)2000-2018 ST Microelectronics*29\r\n",
                            data = sentence.data(using: .ascii)!,
                            messages = try await parser.parse(data: data)

                        expect(messages).to(haveCount(2))
                        guard let payload = (messages[1] as? Message)?.payload else {
                            fail("expected Message, got \(messages[1])")
                            return
                        }

                        expect(payload).to(equal(.text("(C)2000-2018 ST Microelectronics", identifier: nil)))
                    }
                }
            }

            describe(".flush") {
                it("flushes incomplete messages") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .text,
                                fields: [3, 1, 24, "FIRST PART OF MESSAGE "]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .text,
                                fields: [3, 2, nil, "SECOND PART OF MESSAGE"])
                        ],
                        data = sentences.joined().data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(2))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    expect(message.payload).to(equal(.text("FIRST PART OF MESSAGE SECOND PART OF MESSAGE", identifier: 24)))
                }
            }
        }
    }
}
