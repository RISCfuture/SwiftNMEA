import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class HDTSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.44 HDT") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .magneticCompass, format: .trueHeading,
                        fields: [190.1, "T"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .trueHeading(heading) = payload else {
                    fail("expected .trueHeading, got \(payload)")
                    return
                }

                expect(heading.angle).to(equal(.init(value: 190.1, unit: .degrees)))
                expect(heading.reference).to(equal(.true))
            }
        }
    }
}
