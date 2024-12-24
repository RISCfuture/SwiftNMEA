import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class TRDSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.83 TRD") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .propulsion, format: .thrusterResponse,
                        fields: [1, 12.3, "P", 23.4, "D", 123.4, "B", "R"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .thrusterResponse(number, RPM, pitch, azimuth) = payload else {
                    fail("expected .thrusterResponse, got \(payload)")
                    return
                }

                expect(number).to(equal(1))
                expect(RPM).to(equal(.percent(12.3)))
                expect(pitch).to(equal(.value(.init(value: 23.4, unit: .degrees))))
                expect(azimuth).to(equal(.init(value: 123.4, unit: .degrees)))
            }
        }
    }
}
