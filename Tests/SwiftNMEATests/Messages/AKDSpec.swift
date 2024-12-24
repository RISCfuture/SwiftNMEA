import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class AKDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.9 AKD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -150),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .detailAlarmAcknowledgement,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "SG", "PU", 1, 2, "SG", nil, 1]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .detailAlarmAcknowledgement(actualTime, alarm, instance, sender, senderInstance) = payload else {
                    fail("expected .detailAlarmAcknowledgement, got \(payload)")
                    return
                }
                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(alarm).to(equal(.steeringGear(subsystem: .powerUnit(type: .powerFail))))
                expect(instance).to(equal(1))
                expect(sender).to(equal(.steeringGear(subsystem: nil)))
                expect(senderInstance).to(equal(1))
            }
        }
    }
}
