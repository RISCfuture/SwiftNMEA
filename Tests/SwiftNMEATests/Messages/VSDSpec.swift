import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class VSDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.97 VSD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: 259_200),
                    timeComponents = Calendar.current.dateComponents(in: .gmt, from: time),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISVoyageData,
                        fields: [51, 25.5, 8191, "KOAK",
                                 hmsFractionFormatter.string(from: time), dayFormatter.string(from: time), monthFormatter.string(from: time),
                                 0, 0]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .AISVoyageData(shipType, maxDraft, soulsOnboard, destination, destinationETA, navStatus, regionalFlags) = payload else {
                    fail("expected .AISVoyageData, got \(payload)")
                    return
                }

                expect(shipType).to(equal(.SAR))
                expect(maxDraft).to(equal(.available(.init(value: 25.5, unit: .meters))))
                expect(soulsOnboard).to(equal(.available(8191)))
                expect(destination).to(equal(.available("KOAK")))
                expect(destinationETA.month).to(equal(.available(timeComponents.month!)))
                expect(destinationETA.day).to(equal(.available(timeComponents.day!)))
                expect(destinationETA.hour).to(equal(.available(timeComponents.hour!)))
                expect(destinationETA.minute).to(equal(.available(timeComponents.minute!)))
                expect(navStatus).to(equal(.underway))
                expect(regionalFlags).to(equal(0))
            }

            it("parses unavailable values") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISVoyageData,
                        fields: [nil, 0.0, 0, "@@@@@@@@@@@@@@@@@@@@",
                                 "246000.00", "00", "00",
                                 nil, 0]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .AISVoyageData(shipType, maxDraft, soulsOnboard, destination, destinationETA, navStatus, regionalFlags) = payload else {
                    fail("expected .AISVoyageData, got \(payload)")
                    return
                }

                expect(shipType).to(beNil())
                expect(maxDraft).to(equal(.unavailable))
                expect(soulsOnboard).to(equal(.unavailable))
                expect(destination).to(equal(.unavailable))
                expect(destinationETA.month).to(equal(.unavailable))
                expect(destinationETA.day).to(equal(.unavailable))
                expect(destinationETA.hour).to(equal(.unavailable))
                expect(destinationETA.minute).to(equal(.unavailable))
                expect(navStatus).to(beNil())
                expect(regionalFlags).to(equal(0))
            }
        }
    }
}
