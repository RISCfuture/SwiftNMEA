import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class ZTGSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.109 ZTG") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -1),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .timeToDestination,
                        fields: [hmsFractionFormatter.string(from: time), "010203.04", "KOAK"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .timeToDestination(observation, timeToGo, destinationID) = payload else {
                    fail("expected .timeToDestination, got \(payload)")
                    return
                }

                expect(observation).to(beCloseTo(time, within: 0.01))
                expect(timeToGo).to(equal(.seconds(3723) + .milliseconds(40)))
                expect(destinationID).to(equal("KOAK"))
            }
        }
    }
}
