import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class NAKSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.61 NAK") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commDataReceiver, format: .negativeAcknowledgement,
                        fields: ["SG", "HSC", nil, 10, "DISCONNECTED"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .negativeAcknowledgement(talker, format, uniqueID, reasonCode, reason) = payload else {
                    fail("expected .negativeAcknowledgement, got \(payload)")
                    return
                }

                expect(talker).to(equal(.steering))
                expect(format).to(equal(.headingSteeringCommand))
                expect(uniqueID).to(beNil())
                expect(reasonCode).to(equal(.unable))
                expect(reason).to(equal("DISCONNECTED"))
            }
        }
    }
}
