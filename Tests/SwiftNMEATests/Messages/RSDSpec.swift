import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RSDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.74 RSD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .radarSystemData,
                        fields: [1.2, 23.4, 3.4, 45.6,
                                 6.5, 65.4, 4.3, 43.2,
                                 123.4, 234.5,
                                 40.0, "N", "N"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .radarSystemData(origin1, VRM1, EBL1, origin2, VRM2, EBL2, cursor, rangeScale, rotation) = payload else {
                    fail("expected .radarSystemData, got \(payload)")
                    return
                }

                expect(origin1.bearing.angle).to(equal(.init(value: 23.4, unit: .degrees)))
                expect(origin1.bearing.reference).to(equal(.relative))
                expect(origin1.range).to(equal(.init(value: 1.2, unit: .nauticalMiles)))
                expect(VRM1).to(equal(.init(value: 3.4, unit: .nauticalMiles)))
                expect(EBL1.angle).to(equal(.init(value: 45.6, unit: .degrees)))
                expect(EBL1.reference).to(equal(.relative))

                expect(origin2.bearing.angle).to(equal(.init(value: 65.4, unit: .degrees)))
                expect(origin2.bearing.reference).to(equal(.relative))
                expect(origin2.range).to(equal(.init(value: 6.5, unit: .nauticalMiles)))
                expect(VRM2).to(equal(.init(value: 4.3, unit: .nauticalMiles)))
                expect(EBL2.angle).to(equal(.init(value: 43.2, unit: .degrees)))
                expect(EBL2.reference).to(equal(.relative))

                expect(rangeScale).to(equal(.init(value: 40, unit: .nauticalMiles)))
                expect(rotation).to(equal(.northUp))

                expect(cursor.bearing.angle).to(equal(.init(value: 234.5, unit: .degrees)))
                expect(cursor.bearing.reference).to(equal(.relative))
                expect(cursor.range).to(equal(.init(value: 123.4, unit: .nauticalMiles)))
            }
        }
    }
}
