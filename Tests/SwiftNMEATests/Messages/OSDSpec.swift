import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class OSDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.64 OSD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .integratedNavigation, format: .ownshipData,
                        fields: [5.0, "A",
                                 8.0, "B",
                                 12.5, "R",
                                 1.5, 2.1, "N"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .ownshipData(heading, headingValid, course, courseReference, speed, speedReference, set, drift) = payload else {
                    fail("expected .ownshipData, got \(payload)")
                    return
                }

                expect(heading.angle).to(equal(.init(value: 5, unit: .degrees)))
                expect(heading.reference).to(equal(.true))
                expect(headingValid).to(beTrue())
                expect(course.angle).to(equal(.init(value: 8, unit: .degrees)))
                expect(course.reference).to(equal(.true))
                expect(courseReference).to(equal(.bottom))
                expect(speed).to(equal(.init(value: 12.5, unit: .knots)))
                expect(speedReference).to(equal(.radar))
                expect(set.angle).to(equal(.init(value: 1.5, unit: .degrees)))
                expect(set.reference).to(equal(.true))
                expect(drift).to(equal(.init(value: 2.1, unit: .knots)))
            }
        }
    }
}
