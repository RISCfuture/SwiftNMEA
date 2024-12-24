import Nimble
import Quick
@testable import SwiftNMEA

final class ABMSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.4 ABM") {
            describe(".parse") {
                it("parses a sentence") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data1 = "This is some very interesting binary data".data(using: .ascii)!,
                        data2 = "Each message must be no more than 58 characters (117 bytes)".data(using: .ascii)!,
                        (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 48),
                        (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 48)

                    let sentences1 = encapsulatedSentences(format: .AISBinaryMessage,
                                                           from: chunks1,
                                                           fillBits: fillBits1,
                                                           sequenceID: 0,
                                                           otherFields: [123456789, 0, "01"]),
                        sentences2 = encapsulatedSentences(format: .AISBinaryMessage,
                                                           from: chunks2,
                                                           fillBits: fillBits2,
                                                           sequenceID: 1,
                                                           otherFields: [987654321, 0, "02"]),
                        data = (sentences1 + sentences2).joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(6))
                    guard let payload1 = (messages[2] as? Message)?.payload else {
                        fail("expected Message, got \(messages[2])")
                        return
                    }
                    guard let payload2 = (messages[5] as? Message)?.payload else {
                        fail("expected Message, got \(messages[5])")
                        return
                    }
                    expect(payload1).to(equal(
                        .AISBinaryMessage(sequentialIdentifier: 0,
                                          MMSI: 123456789,
                                          channel: .noPreference,
                                          messageID: .positionReportSOTDMA,
                                          data: data1)
                    ))
                    expect(payload2).to(equal(
                        .AISBinaryMessage(sequentialIdentifier: 1,
                                          MMSI: 987654321,
                                          channel: .noPreference,
                                          messageID: .positionReportSOTDMA_2,
                                          data: data2)
                    ))
                }

                it("throws an error for missing fields") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data = "This is some very interesting binary data".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 48),
                        sentences = encapsulatedSentences(format: .AISBinaryMessage,
                                                          from: chunks,
                                                          fillBits: fillBits,
                                                          sequenceID: 0,
                                                          otherFields: [nil, 0, "01"]),
                        sentenceData = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: sentenceData)

                    expect(messages).to(haveCount(4))

                    guard let error = messages[1] as? MessageError
                    else {
                        fail("expected MessageError, got \(messages[1])")
                        return
                    }
                    expect(error.type).to(equal(.missingRequiredValue))
                    expect(error.fieldNumber).to(equal(3))

                    guard let error = messages[3] as? MessageError
                    else {
                        fail("expected MessageError, got \(messages[3])")
                        return
                    }
                    expect(error.type).to(equal(.missingRequiredValue))
                    expect(error.fieldNumber).to(equal(3))
                }

                it("throws an error for a wrong sentence number") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data = "Each message must be no more than 58 characters (117 bytes)".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 48),
                        sentences = [
                            createSentence(delimiter: .encapsulated, talker: .commVHF, format: .AISBinaryMessage,
                                           fields: [2, 1, 1,
                                                    1234567890, 1, 1,
                                                    chunks[0], fillBits]),
                            createSentence(delimiter: .encapsulated, talker: .commVHF, format: .AISBinaryMessage,
                                           fields: [2, 1, 1,
                                                    1234567890, 1, 1,
                                                    chunks[1], fillBits])
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

                    let data = "1234567890123456789012345678901234567890123456789012345678901234567890".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 48)

                    let sentences = encapsulatedSentences(format: .AISBinaryMessage,
                                                          from: chunks,
                                                          fillBits: fillBits,
                                                          sequenceID: 0,
                                                          otherFields: [123456789, 0, "01"]),
                        sentenceData = sentences[0].data(using: .ascii)!

                    let parsed = try await parser.parse(data: sentenceData)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .AISBinaryMessage(sequentialIdentifier, MMSI, channel, messageID, actualData) = message.payload else {
                        fail("expected .AISBinaryMessage, got \(message)")
                        return
                    }

                    expect(sequentialIdentifier).to(equal(0))
                    expect(MMSI).to(equal(123456789))
                    expect(channel).to(equal(.noPreference))
                    expect(messageID).to(equal(.positionReportSOTDMA))
                    expect(actualData).to(equal("12345678901234567890123456789012345".data(using: .ascii)!))
                }

                it("throws an error for missing fields") {
                    let parser = SwiftNMEA(),
                        sixBit = SixBitCoder()

                    let data = "1234567890123456789012345678901234567890123456789012345678901234567890".data(using: .ascii)!,
                        (chunks, fillBits) = sixBit.encode(data, chunkSize: 48)

                    let sentences = encapsulatedSentences(format: .AISBinaryMessage,
                                                          from: chunks,
                                                          fillBits: fillBits,
                                                          sequenceID: 0,
                                                          otherFields: [123456789, 0, "01"]),
                        sentenceData = sentences[0].data(using: .ascii)!

                    let parsed = try await parser.parse(data: sentenceData)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .AISBinaryMessage(sequentialIdentifier, MMSI, channel, messageID, actualData) = message.payload else {
                        fail("expected .AISBinaryMessage, got \(message)")
                        return
                    }

                    expect(sequentialIdentifier).to(equal(0))
                    expect(MMSI).to(equal(123456789))
                    expect(channel).to(equal(.noPreference))
                    expect(messageID).to(equal(.positionReportSOTDMA))
                    expect(actualData).to(equal("12345678901234567890123456789012345".data(using: .ascii)!))
                }
            }
        }
    }
}
