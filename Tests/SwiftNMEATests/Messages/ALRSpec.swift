import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class ALRSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.11 ALR") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -1500),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .alarmState,
                        fields: [hmsFractionFormatter.string(from: time),
                                 123, "A", "V", "test alarm"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .alarmState(changeTime, identifier, thresholdExceeded, acknowledged, description) = payload else {
                    fail("expected .alarmState, got \(payload)")
                    return
                }
                expect(changeTime).to(beCloseTo(time, within: 0.01))
                expect(identifier).to(equal(123))
                expect(thresholdExceeded).to(beTrue())
                expect(acknowledged).to(beFalse())
                expect(description).to(equal("test alarm"))
            }
        }
    }
}
