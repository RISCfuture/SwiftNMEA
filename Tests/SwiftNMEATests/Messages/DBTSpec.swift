import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class DBTSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.21 DBT") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .depthSounder, format: .depthBelowTransducer,
                        fields: [60, "f", 18.29, "M", 10, "F"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                expect(payload).to(equal(.depthBelowTransducer([
                    .init(value: 60, unit: .feet),
                    .init(value: 18.29, unit: .meters),
                    .init(value: 10, unit: .fathoms)
                ])))
            }
        }
    }
}
