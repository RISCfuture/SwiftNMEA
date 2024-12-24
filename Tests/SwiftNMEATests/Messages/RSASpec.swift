import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RSASpec: AsyncSpec {
    override static func spec() {
        describe("8.3.73 RSA") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .steering, format: .rudderSensorAngle,
                        fields: [1.2, "A", -2.3, "V"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .rudderSensorAngle(starboard, port, starboardValid, portValid) = payload else {
                    fail("expected .rudderSensorAngle, got \(payload)")
                    return
                }

                expect(starboard).to(equal(1.2))
                expect(starboardValid).to(beTrue())
                expect(port).to(equal(-2.3))
                expect(portValid).to(beFalse())
            }
        }
    }
}
