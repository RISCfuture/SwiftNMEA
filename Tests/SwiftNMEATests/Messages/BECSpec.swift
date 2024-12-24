import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class BECSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.14 BEC") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -1200),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .integratedNavigation, format: .bearingDistanceToWaypointDR,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "3730.00", "N", "12145.00", "W",
                                 120.5, "T", 125.1, "M",
                                 123.4, "N",
                                 "KSQL"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .bearingDistanceToWaypointDR(observationTime, waypointPosition, bearingTrue, bearingMagnetic, distance, waypointID) = payload else {
                    fail("expected .bearingDistanceToWaypointDR, got \(payload)")
                    return
                }

                expect(observationTime).to(beCloseTo(time, within: 0.01))
                expect(waypointPosition).to(equal(.init(latitude: 37.5, longitude: -121.75)))
                expect(bearingTrue).to(equal(.init(degrees: 120.5, reference: .true)))
                expect(bearingMagnetic).to(equal(.init(degrees: 125.1, reference: .magnetic)))
                expect(distance).to(equal(.init(value: 123.4, unit: .nauticalMiles)))
                expect(waypointID).to(equal("KSQL"))
            }
        }
    }
}
