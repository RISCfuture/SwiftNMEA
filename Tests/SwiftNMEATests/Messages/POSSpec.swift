import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class POSSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.65 POS") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .integratedNavigation, format: .positionDimensions,
                        fields: ["AG", "00",
                                 "A", 1.2, 3.4, 5.6,
                                 "V", 7.8, 9.9,
                                 "R"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .positionDimensions(equipment, equipmentNumber, positionValid, position, dimensionsValid, dimensions, status) = payload else {
                    fail("expected .positionDimensions, got \(payload)")
                    return
                }

                expect(equipment).to(equal(.autopilotGeneral))
                expect(equipmentNumber).to(equal(0))
                expect(positionValid).to(beTrue())
                expect(position.x).to(equal(.init(value: 1.2, unit: .meters)))
                expect(position.y).to(equal(.init(value: 3.4, unit: .meters)))
                expect(position.z).to(equal(.init(value: 5.6, unit: .meters)))
                expect(dimensionsValid).to(beFalse())
                expect(dimensions.width).to(equal(.init(value: 7.8, unit: .meters)))
                expect(dimensions.length).to(equal(.init(value: 9.9, unit: .meters)))
                expect(status).to(equal(.reply))
            }
        }
    }
}
