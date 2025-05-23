import Nimble
import Quick
@testable import SwiftNMEA

final class AAMSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.2 AAM") {
            it("parses the sentence from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCAAM,V,A,.15,N,CHAT-N6*56\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .waypointArrivalAlarm(arrivalCircleEntered, perpendicularPassed, arrivalCircleRadius, waypoint) = payload else {
                    fail("expected .waypointArrivalAlarm, got \(payload)")
                    return
                }

                expect(arrivalCircleEntered).to(beFalse())
                expect(perpendicularPassed).to(beTrue())
                expect(arrivalCircleRadius).to(equal(.init(value: 0.15, unit: .nauticalMiles)))
                expect(waypoint).to(equal("CHAT-N6"))
            }
        }
    }
}
