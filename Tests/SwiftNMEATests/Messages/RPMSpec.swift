import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RPMSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.72 RPM") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .propulsion, format: .revolutions,
                        fields: ["S", 0, 1.2, -2.3, "A"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .revolutions(source, number, speed, pitch, isValid) = payload else {
                    fail("expected .revolutions, got \(payload)")
                    return
                }

                expect(source).to(equal(.shaft))
                expect(number).to(equal(0))
                expect(speed).to(equal(.init(value: 1.2, unit: .revolutionsPerMinute)))
                expect(pitch).to(equal(-2.3))
                expect(isValid).to(beTrue())
            }
        }
    }
}
