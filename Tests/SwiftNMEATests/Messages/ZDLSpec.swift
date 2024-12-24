import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class ZDLSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.107 ZDL") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .timeDistanceToVariablePoint,
                        fields: ["010203.04", 12.3, "C"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .timeDistanceToVariablePoint(time, distance, type) = payload else {
                    fail("expected .timeDistanceToVariablePoint, got \(payload)")
                    return
                }

                expect(time).to(equal(.seconds(3723) + .milliseconds(40)))
                expect(distance).to(equal(.init(value: 12.3, unit: .nauticalMiles)))
                expect(type).to(equal(.collision))
            }
        }
    }
}
