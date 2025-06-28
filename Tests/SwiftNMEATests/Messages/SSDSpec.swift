import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class SSDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.77 SSD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .automaticID, format: .AISShipStaticData,
                        fields: ["N171MA", "@@@@@@@@@@@@@@@@@@@@",
                                 12, 23, nil, 0,
                                 0, "AI"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .AISShipStaticData(callsign, name, pointA, pointB, pointC, pointD, DTEAvailable, source) = payload else {
                    fail("expected .AISShipStaticData, got \(payload)")
                    return
                }

                expect(callsign).to(equal(.available("N171MA")))
                expect(name).to(equal(.unavailable))
                expect(pointA).to(equal(.available(.init(value: 12, unit: .meters))))
                expect(pointB).to(equal(.available(.init(value: 23, unit: .meters))))
                expect(pointC).to(beNil())
                expect(pointD).to(equal(.unavailable))
                expect(DTEAvailable).to(beTrue())
                expect(source).to(equal(.automaticID))
            }
        }
    }
}
