import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class XTESpec: AsyncSpec {
    override static func spec() {
        describe("8.3.104 XTE") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .radar, format: .crossTrackError,
                        fields: ["A", "V",
                                 12.3, "L", "N",
                                 "A"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .crossTrackError(error, mode, LORANC_blinkSNRFlag, LORANC_cycleLockWarningFlag) = payload else {
                    fail("expected .crossTrackError, got \(payload)")
                    return
                }

                expect(error).to(equal(.init(value: -12.3, unit: .nauticalMiles)))
                expect(mode).to(equal(.autonomous))
                expect(LORANC_blinkSNRFlag).to(beFalse())
                expect(LORANC_cycleLockWarningFlag).to(beTrue())
            }
        }
    }
}
