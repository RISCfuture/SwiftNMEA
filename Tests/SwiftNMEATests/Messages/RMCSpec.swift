import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RMCSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.69 RMC") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -0.5),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .GPS, format: .GNSSMinimumData,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "A",
                                 "3630.00", "N", "12215.00", "W",
                                 12.3, 123.4,
                                 dateFormatter.string(from: time),
                                 1.2, "W",
                                 "D", "S"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .GNSSMinimumData(actualTime, isValid, position, speed, course, magneticVariation, mode, status) = payload else {
                    fail("expected .GNSSMinimumData, got \(payload)")
                    return
                }

                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(isValid).to(beTrue())
                expect(position.latitude).to(equal(.init(value: 36.5, unit: .degrees)))
                expect(position.longitude).to(equal(.init(value: -122.25, unit: .degrees)))
                expect(speed).to(equal(.init(value: 12.3, unit: .knots)))
                expect(course.angle).to(equal(.init(value: 123.4, unit: .degrees)))
                expect(course.reference).to(equal(.true))
                expect(magneticVariation).to(equal(.init(value: -1.2, unit: .degrees)))
                expect(mode).to(equal(.differential))
                expect(status).to(equal(.safe))
            }
        }
    }
}
