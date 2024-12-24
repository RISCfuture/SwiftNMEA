import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class FIRSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.30 FIR") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -10),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .fireDetection, format: .fireDetection,
                        fields: ["E", hmsFractionFormatter.string(from: time),
                                 "FS", "AB", 12, 2,
                                 "A", "V", "GALLEY"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .fireDetection(type, actualTime, detector, zone, loop, number, condition, isAcknowledged, description) = payload else {
                    fail("expected .fireDetection, got \(payload)")
                    return
                }

                expect(type).to(equal(.event))
                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(detector).to(equal(.smoke))
                expect(zone).to(equal("AB"))
                expect(loop).to(equal(12))
                expect(number).to(equal(2))
                expect(condition).to(equal(.activation))
                expect(isAcknowledged).to(beFalse())
                expect(description).to(equal("GALLEY"))
            }
        }
    }
}
