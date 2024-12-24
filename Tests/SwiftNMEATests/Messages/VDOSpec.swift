import Nimble
import Quick
@testable import SwiftNMEA

final class VDOSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.91 VDO") {
            describe(".parse") {
                it("parses a sentence") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data1 = "This is some very interesting binary data".data(using: .ascii)!,
                        data2 = "Each message must be no more than 60 characters to fit in a single sentence".data(using: .ascii)!,
                        (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 60),
                        (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 60)

                    let sentences1 = encapsulatedSentences(format: .VDLOwnshipReport,
                                                           from: chunks1,
                                                           fillBits: fillBits1,
                                                           sequenceID: 0,
                                                           otherFields: ["A"]),
                        sentences2 = encapsulatedSentences(format: .VDLOwnshipReport,
                                                           from: chunks2,
                                                           fillBits: fillBits2,
                                                           sequenceID: 1,
                                                           otherFields: ["B"]),
                        data = (sentences1 + sentences2).joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))
                    guard let payload1 = (messages[1] as? Message)?.payload else {
                        fail("expected Message, got \(messages[1])")
                        return
                    }
                    guard let payload2 = (messages[4] as? Message)?.payload else {
                        fail("expected Message, got \(messages[4])")
                        return
                    }
                    expect(payload1).to(equal(.VDLOwnshipReport(data1, channel: .A)))
                    expect(payload2).to(equal(.VDLOwnshipReport(data2, channel: .B)))
                }

                it("parses a 62-character (46-byte) sentence when some fields are nil") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data = "1234567890123456789012345678901234567890123456".data(using: .ascii)!,
                    (chunks, fillBits) = sixBit.encode(data, chunkSize: 62),
                    sentence = createSentence(delimiter: .encapsulated, talker: .commVHF, format: .VDLOwnshipReport,
                                              fields: [1, 1, nil, nil, chunks[0], fillBits]),
                    sentenceData = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: sentenceData)

                    expect(messages).to(haveCount(2))
                    guard let payload = (messages[1] as? Message)?.payload else {
                        fail("expected Message, got \(messages[2])")
                        return
                    }
                    guard case let .VDLOwnshipReport(actualData, channel) = payload else {
                        fail("expected .VDLOwnshipReport, got \(payload)")
                        return
                    }
                    expect(actualData).to(equal(data))
                    expect(channel).to(beNil())
                }

                it("throws an error for an incorrect sentence number") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data = "This data is exactly 62 characters long. This data is exactly ".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 60),
                        sentences = [
                            createSentence(delimiter: .encapsulated, talker: .commVHF, format: .VDLOwnshipReport,
                                           fields: [2, 1, nil, nil, chunks[0], fillBits]),
                            createSentence(delimiter: .encapsulated, talker: .commVHF, format: .VDLOwnshipReport,
                                           fields: [2, 3, nil, nil, chunks[1], fillBits])
                        ],
                        sentenceData = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: sentenceData)

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
                        sixBit = SixBitCoder()

                    let data = "1234567890123456789012345678901234567890123456789012".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)

                    let sentences = encapsulatedSentences(format: .VDLOwnshipReport,
                                                          from: chunks,
                                                          fillBits: fillBits,
                                                          sequenceID: 0,
                                                          otherFields: ["A"]),
                        sentenceData = sentences[0].data(using: .ascii)!

                    let parsed = try await parser.parse(data: sentenceData)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .VDLOwnshipReport(message, channel) = message.payload else {
                        fail("expected .VDLMessage, got \(message)")
                        return
                    }

                    expect(channel).to(equal(.A))
                    expect(message).to(equal("12345678901234567890123456789012345678901234".data(using: .ascii)!))
                }
            }
        }
    }
}
