import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class HSSSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.48 HSS") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .hullStressMonitoring, format: .hullStress,
                        fields: ["OUTER1", 1.23, "V"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .hullStress(value, point, isValid) = payload else {
                    fail("expected .hullStress, got \(payload)")
                    return
                }

                expect(value).to(equal(1.23))
                expect(point).to(equal("OUTER1"))
                expect(isValid).to(beFalse())
            }
        }
    }
}
