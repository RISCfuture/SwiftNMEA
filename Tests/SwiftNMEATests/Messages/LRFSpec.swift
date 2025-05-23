import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class LRFSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.53 LRF and friends") {
            describe(".parse") {
                it("parses a sentence") {
                    let parser = SwiftNMEA(),
                        fixTime = Date(timeIntervalSinceNow: -5),
                        ETA = Date(timeIntervalSinceNow: 60000),
                        LRF = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeFunction,
                            fields: [1, 1234567890, "MORIARTY",
                                     "ABCEFIOPUW", "22222222222"]),
                        LR1 = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply1,
                            fields: [1, 1234567890,
                                     9876543210, "HAIL MARY", "HAIL^5EMRY", 1029384756]),
                        LR2 = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply2,
                            fields: [1, 1234567890,
                                     dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
                                     "3530.00", "N", "12115.00", "W",
                                     "225.5", "T",
                                     "12.3", "N"]),
                        LR3 = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply3,
                            fields: [1, 1234567890,
                                     "PORT OF OAKLAND",
                                     dateFormatter.string(from: ETA), hmsFractionFormatter.string(from: ETA),
                                     1.2, 31, 34.5, 12.3, 81, 123]),
                        data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)! + LR3.data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))
                    guard let payload = (messages[4] as? Message)?.payload else {
                        fail("expected Message, got \(messages[4])")
                        return
                    }
                    guard case let .AISLongRangeReply(requestorMMSI, requestorName, replyStatuses, actualFixTime,
                                                      shipName, shipCallsign, shipIMO, position, course,
                                                      speed, destination, actualETA, shipType, shipType2, length,
                                                      breadth, draught, soulsOnboard) = payload else {
                        fail("expected .AISLongRangeReply, got \(payload)")
                        return
                    }

                    expect(requestorMMSI).to(equal(1234567890))
                    expect(requestorName).to(equal("MORIARTY"))
                    expect(replyStatuses).to(equal([
                        .shipID: .available,
                        .dateTime: .available,
                        .position: .available,
                        .course: .available,
                        .speed: .available,
                        .destination: .available,
                        .draught: .available,
                        .cargo: .available,
                        .shipDimensions: .available,
                        .soulsOnboard: .available
                    ]))
                    expect(shipName).to(equal("HAIL MARY"))
                    expect(shipCallsign).to(equal("HAIL^MRY"))
                    expect(shipIMO).to(equal(1029384756))

                    expect(actualFixTime).to(beCloseTo(fixTime, within: 0.01))
                    expect(position!.latitude).to(equal(.init(value: 35.5, unit: .degrees)))
                    expect(position!.longitude).to(equal(.init(value: -121.25, unit: .degrees)))
                    expect(course!.angle).to(equal(.init(value: 225.5, unit: .degrees)))
                    expect(course!.reference).to(equal(.true))
                    expect(speed).to(equal(.init(value: 12.3, unit: .knots)))

                    expect(destination).to(equal("PORT OF OAKLAND"))
                    expect(actualETA).to(beCloseTo(ETA, within: 0.01))
                    expect(draught).to(equal(.init(value: 1.2, unit: .meters)))
                    expect(shipType).to(equal(.vessel(operation: .towing)))
                    expect(length).to(equal(.init(value: 34.5, unit: .meters)))
                    expect(breadth).to(equal(.init(value: 12.3, unit: .meters)))
                    expect(shipType2).to(equal(.tanker(cargo: .categoryX)))
                    expect(soulsOnboard).to(equal(123))
                }

                it("throws an error if a duplicate sentence is received") {
                    let parser = SwiftNMEA(),
                    fixTime = Date(timeIntervalSinceNow: -5),
                    LRF = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeFunction,
                        fields: [1, 1234567890, "MORIARTY",
                                 "ABCEFIOPUW", "22222222222"]),
                    LR1 = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply1,
                        fields: [1, 1234567890,
                                 9876543210, "HAIL MARY", "HAILMRY", 1029384756]),
                    LR2 = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply2,
                        fields: [1, 1234567890,
                                 dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
                                 "3530.00", "N", "12115.00", "W",
                                 "225.5", "T",
                                 "12.3", "N"]),
                    // oops! another LR2
                    LR2_2 = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply2,
                        fields: [1, 1234567890,
                                 dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
                                 "3530.00", "N", "12115.00", "W",
                                 "225.5", "T",
                                 "12.3", "N"]),
                    data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)! + LR2_2.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))
                    guard let error = messages[4] as? MessageError else {
                        fail("expected MessageError, got \(messages[4])")
                        return
                    }
                        expect(error.type).to(equal(.unexpectedFormat))
                }

                it("throws an error if an unexpected sentence is received") {
                    let parser = SwiftNMEA(),
                    ETA = Date(timeIntervalSinceNow: 60000),
                    LRF = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeFunction,
                        fields: [1, 1234567890, "MORIARTY",
                                 "ABCEF", "22222222222"]),
                    LR1 = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply1,
                        fields: [1, 1234567890,
                                 9876543210, "HAIL MARY", "HAILMRY", 1029384756]),
                    // oops! unexpected LR3
                    LR3 = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply3,
                        fields: [1, 1234567890,
                                 "PORT OF OAKLAND",
                                 dateFormatter.string(from: ETA), hmsFractionFormatter.string(from: ETA),
                                 1.2, 31, 34.5, 12.3, 81, 123]),
                    data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR3.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(4))
                    guard let error = messages[3] as? MessageError else {
                        fail("expected MessageError, got \(messages[3])")
                        return
                    }
                        expect(error.type).to(equal(.unexpectedFormat))
                }
            }

            describe(".flush") {
                it("flushes incomplete sentences") {
                    let parser = SwiftNMEA(),
                        fixTime = Date(timeIntervalSinceNow: -5),
                        LRF = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeFunction,
                            fields: [1, 1234567890, "MORIARTY",
                                     "ABCEFIOPUW", "22222222222"]),
                        LR1 = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply1,
                            fields: [1, 1234567890,
                                     9876543210, "HAIL MARY", "HAILMRY", 1029384756]),
                        LR2 = createSentence(
                            delimiter: .parametric, talker: .commVHF, format: .AISLongRangeReply2,
                            fields: [1, 1234567890,
                                     dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
                                     "3530.00", "N", "12115.00", "W",
                                     "225.5", "T",
                                     "12.3", "N"]),
                        data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(3))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .AISLongRangeReply(requestorMMSI, requestorName, replyStatuses, actualFixTime,
                                                      shipName, shipCallsign, shipIMO, position, course,
                                                      speed, destination, actualETA, shipType, shipType2, length,
                                                      breadth, draught, soulsOnboard) = message.payload else {
                        fail("expected .AISLongRangeReply, got \(message)")
                        return
                    }

                    expect(requestorMMSI).to(equal(1234567890))
                    expect(requestorName).to(equal("MORIARTY"))
                    expect(replyStatuses).to(equal([
                        .shipID: .available,
                        .dateTime: .available,
                        .position: .available,
                        .course: .available,
                        .speed: .available,
                        .destination: .available,
                        .draught: .available,
                        .cargo: .available,
                        .shipDimensions: .available,
                        .soulsOnboard: .available
                    ]))
                    expect(shipName).to(equal("HAIL MARY"))
                    expect(shipCallsign).to(equal("HAILMRY"))
                    expect(shipIMO).to(equal(1029384756))

                    expect(actualFixTime).to(beCloseTo(fixTime, within: 0.01))
                    expect(position!.latitude).to(equal(.init(value: 35.5, unit: .degrees)))
                    expect(position!.longitude).to(equal(.init(value: -121.25, unit: .degrees)))
                    expect(course!.angle).to(equal(.init(value: 225.5, unit: .degrees)))
                    expect(course!.reference).to(equal(.true))
                    expect(speed).to(equal(.init(value: 12.3, unit: .knots)))

                    expect(destination).to(beNil())
                    expect(actualETA).to(beNil())
                    expect(draught).to(beNil())
                    expect(shipType).to(beNil())
                    expect(length).to(beNil())
                    expect(breadth).to(beNil())
                    expect(shipType2).to(beNil())
                    expect(soulsOnboard).to(beNil())
                }
            }
        }
    }
}
