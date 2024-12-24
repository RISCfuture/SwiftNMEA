import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class VBWSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.89 VBW") {
            it("parses the example from the spec") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .integratedNavigation, format: .speedData,
                        fields: [12.3, 1.2, "A",
                                 23.4, 2.3, "V",
                                 3.4, "A",
                                 5.6, "V"]
                    ),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }

                guard case let .speedData(water, waterValid, ground, groundValid, sternTransverseWater, sternTransverseWaterValid, sternTransverseGround, sternTransverseGroundValid) = payload else {
                    fail("expected .speedData, got \(payload)")
                    return
                }

                expect(water.longitudinal).to(equal(.init(value: 12.3, unit: .knots)))
                expect(water.transverse).to(equal(.init(value: 1.2, unit: .knots)))
                expect(waterValid).to(beTrue())
                expect(ground.longitudinal).to(equal(.init(value: 23.4, unit: .knots)))
                expect(ground.transverse).to(equal(.init(value: 2.3, unit: .knots)))
                expect(groundValid).to(beFalse())
                expect(sternTransverseWater).to(equal(.init(value: 3.4, unit: .knots)))
                expect(sternTransverseWaterValid).to(beTrue())
                expect(sternTransverseGround).to(equal(.init(value: 5.6, unit: .knots)))
                expect(sternTransverseGroundValid).to(beFalse())
            }
        }
    }
}
