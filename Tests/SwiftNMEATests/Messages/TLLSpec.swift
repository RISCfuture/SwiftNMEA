import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class TLLSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.81 TLL") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -10),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .targetPosition,
                        fields: [12,
                                 "3730.00", "N", "12115.00", "W",
                                 "TGT1",
                                 hmsFractionFormatter.string(from: time),
                                 "Q", nil]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .targetPosition(number, position, name, actualTime, status, isReference) = payload else {
                    fail("expected .targetPosition, got \(payload)")
                    return
                }

                expect(number).to(equal(12))
                expect(position.latitude).to(equal(.init(value: 37.5, unit: .degrees)))
                expect(position.longitude).to(equal(.init(value: -121.25, unit: .degrees)))
                expect(name).to(equal("TGT1"))
                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(status).to(equal(.query))
                expect(isReference).to(beFalse())
            }
        }
    }
}
