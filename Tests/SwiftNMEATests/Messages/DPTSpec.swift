import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class DPTSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.24 DPT") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .depthSounder, format: .depth,
                        fields: [1.2, -2.3, 40.0]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .depth(depth, offset, maxRange) = payload else {
                    fail("expected .depth, got \(payload)")
                    return
                }

                expect(depth).to(equal(.init(value: 1.2, unit: .meters)))
                expect(offset).to(equal(.init(value: -2.3, unit: .meters)))
                expect(maxRange).to(equal(.init(value: 40.0, unit: .meters)))
            }
        }
    }
}
