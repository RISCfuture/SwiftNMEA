import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class VERSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.93 VER") {
            describe(".parse") {
                it("parses a sentence") {

                    // MARK: Setup

                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 1,
                                         "GPS", "VENDORID", "UNIQUEID",
                                         "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
                                         1]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 2,
                                         nil, nil, "UNIQUEID",
                                         "MSR2", nil, "SOFTV2", "HARDV2",
                                         1]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [1, 1,
                                         "GPS", "VENDORID2", "UNIQUEID2",
                                         "MSR3", "MODELCODE2", "SOFTV3", "HARDV3",
                                         2])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))

                    // MARK: Message 0

                    guard let payload = (messages[2] as? Message)?.payload else {
                        fail("expected Message, got \(messages[2])")
                        return
                    }
                    guard case let .version(type, vendorID, uniqueID, serialNumber, modelCode, softwareRevision, hardwareRevision) = payload else {
                        fail("expected .route, got \(payload)")
                        return
                    }
                    expect(type).to(equal("GPS"))
                    expect(vendorID).to(equal("VENDORID"))
                    expect(uniqueID).to(equal("UNIQUEID"))
                    expect(serialNumber).to(equal("MSR1 MSR2"))
                    expect(modelCode).to(equal("MODELCODE1"))
                    expect(softwareRevision).to(equal("SOFTV1 SOFTV2"))
                    expect(hardwareRevision).to(equal("HARDV1 HARDV2"))

                    // MARK: Message 1

                    guard let payload = (messages[4] as? Message)?.payload else {
                        fail("expected Message, got \(messages[4])")
                        return
                    }
                    guard case let .version(type, vendorID, uniqueID, serialNumber, modelCode, softwareRevision, hardwareRevision) = payload else {
                        fail("expected .version, got \(payload)")
                        return
                    }
                    expect(type).to(equal("GPS"))
                    expect(vendorID).to(equal("VENDORID2"))
                    expect(uniqueID).to(equal("UNIQUEID2"))
                    expect(serialNumber).to(equal("MSR3"))
                    expect(modelCode).to(equal("MODELCODE2"))
                    expect(softwareRevision).to(equal("SOFTV3"))
                    expect(hardwareRevision).to(equal("HARDV3"))
                }

                it("throws an error for an incorrect sentence number") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 1,
                                         "GPS", "VENDORID", "UNIQUEID",
                                         "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
                                         1]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 3,
                                         nil, nil, "UNIQUEID",
                                         "MSR2", nil, "SOFTV2", "HARDV2",
                                         1])
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

                it("throws an error for a missing field") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 1,
                                         nil, "VENDORID", "UNIQUEID",
                                         "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
                                         1]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [2, 2,
                                         nil, nil, "UNIQUEID",
                                         "MSR2", nil, "SOFTV2", "HARDV2",
                                         1])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(3))
                    guard let error = messages[2] as? MessageError else {
                        fail("expected MessageError, got \(messages[2])")
                        return
                    }
                    expect(error.type).to(equal(.missingRequiredValue))
                    expect(error.fieldNumber).to(equal(2))
                }
            }

            describe(".flush") {
                it("flushes incomplete sentences") {
                    let parser = SwiftNMEA(),
                        sentence = createSentence(
                            delimiter: .parametric, talker: .GPS, format: .version,
                            fields: [2, 1,
                                     "GPS", "VENDORID", "UNIQUEID",
                                     "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
                                     1]),
                        data = sentence.data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .version(type, vendorID, uniqueID, serialNumber, modelCode, softwareRevision, hardwareRevision) = message.payload else {
                        fail("expected .version, got \(message)")
                        return
                    }

                    expect(type).to(equal("GPS"))
                    expect(vendorID).to(equal("VENDORID"))
                    expect(uniqueID).to(equal("UNIQUEID"))
                    expect(serialNumber).to(equal("MSR1 "))
                    expect(modelCode).to(equal("MODELCODE1"))
                    expect(softwareRevision).to(equal("SOFTV1 "))
                    expect(hardwareRevision).to(equal("HARDV1 "))
                }

                it("throws an error for a missing field") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [3, 1,
                                         nil, "VENDORID", "UNIQUEID",
                                         "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
                                         1]),
                            createSentence(
                                delimiter: .parametric, talker: .GPS, format: .version,
                                fields: [3, 2,
                                         nil, nil, "UNIQUEID",
                                         "MSR2", nil, "SOFTV2", "HARDV2",
                                         1])
                        ],
                        data = sentences.joined().data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(2))

                    let flushed = try await parser.flush(includeIncomplete: true)
                    expect(flushed).to(haveCount(1))

                    guard let error = flushed[0] as? MessageError else {
                        fail("expected MessageError, got \(flushed[0])")
                        return
                    }
                    expect(error.type).to(equal(.missingRequiredValue))
                    expect(error.fieldNumber).to(equal(2))
                }
            }
        }
    }
}
