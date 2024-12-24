import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class EVESpec: AsyncSpec {
    override static func spec() {
        describe("8.3.29 EVE") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -33),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .waterLevelDetection, format: .event,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "COC", "Change of command"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .event(actualTime, tag, description) = payload else {
                    fail("expected .event, got \(payload)")
                    return
                }

                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(tag).to(equal("COC"))
                expect(description).to(equal("Change of command"))
            }
        }
    }
}
