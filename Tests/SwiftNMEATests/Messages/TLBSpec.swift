import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class TLBSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.80 TLB") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .targetLabels,
                        fields: [1, "A", 2, "B", 3, ""]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                expect(payload).to(equal(.targetLabels([1: "A", 2: "B", 3: nil])))
            }
        }
    }
}
