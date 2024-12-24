import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class STNSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.78 STN") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .depthSounder, format: .talkerID,
                        fields: [12]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                expect(payload).to(equal(.talkerID(12)))
            }
        }
    }
}
