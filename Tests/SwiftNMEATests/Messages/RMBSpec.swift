import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RMBSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.68 RMB") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .GPS, format: .destinationMinimumData,
                        fields: ["A",
                                 0.5, "L",
                                 "KSQL", "KOAK",
                                 "3630.00", "N", "12215.00", "W",
                                 15.5, 272.2, 13.5, "V",
                                 "D"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .destinationMinimumData(isValid, crossTrackError, originID, destinationID, destination, rangeToDestination, bearingToDestination, closingVelocity, isArrived, mode) = payload else {
                    fail("expected .destinationMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beTrue())
                expect(crossTrackError).to(equal(.init(value: -0.5, unit: .nauticalMiles)))
                expect(originID).to(equal("KSQL"))
                expect(destinationID).to(equal("KOAK"))
                expect(destination.latitude).to(equal(.init(value: 36.5, unit: .degrees)))
                expect(destination.longitude).to(equal(.init(value: -122.25, unit: .degrees)))
                expect(rangeToDestination).to(equal(.init(value: 15.5, unit: .nauticalMiles)))
                expect(bearingToDestination.angle).to(equal(.init(value: 272.2, unit: .degrees)))
                expect(bearingToDestination.reference).to(equal(.true))
                expect(closingVelocity).to(equal(.init(value: 13.5, unit: .knots)))
                expect(isArrived).to(beFalse())
                expect(mode).to(equal(.differential))
            }
        }
    }
}
