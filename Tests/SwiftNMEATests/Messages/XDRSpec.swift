import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class WPLSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.103 XDR") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .waterLevelDetection, format: .transducerMeasurements,
                        fields: ["C", 12.3, "C", "SENSOR1",
                                 "S", 1, nil, "SENSOR2",
                                 "G", 23.4, nil, "SENSOR3"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .transducerMeasurements(measurements) = payload else {
                    fail("expected .transducerMeasurements, got \(payload)")
                    return
                }

                expect(measurements).to(haveCount(3))
                expect(measurements[0]).to(equal(.temperature(.init(value: 12.3, unit: .celsius), id: "SENSOR1")))
                expect(measurements[1]).to(equal(.boolean(true, id: "SENSOR2")))
                expect(measurements[2]).to(equal(.generic(23.4, id: "SENSOR3")))
            }
        }
    }
}
