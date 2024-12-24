import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class GSASpec: AsyncSpec {
    override static func spec() {
        describe("8.3.39 GSA") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .GPS, format: .GNSS_DOP,
                        fields: ["A", 3,
                                 "05", "03", "01", "02", "04",
                                 0.5, 0.6, 0.7,
                                 1]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .GNSS_DOP(PDOP, HDOP, VDOP, auto3D, solution, ids) = payload else {
                    fail("expected .GNSS_DOP, got \(payload)")
                    return
                }

                expect(PDOP).to(equal(0.5))
                expect(HDOP).to(equal(0.6))
                expect(VDOP).to(equal(0.7))
                expect(auto3D).to(beTrue())
                expect(solution).to(equal(.fix3D))
                expect(ids).to(equal([
                    .GPS(5, signal: nil),
                    .GPS(3, signal: nil),
                    .GPS(1, signal: nil),
                    .GPS(2, signal: nil),
                    .GPS(4, signal: nil)
                ]))
            }

            it("parses a sentence from a STA8089FG") {
                let parser = SwiftNMEA(),
                    sentence = "$GPGSA,A,1,,,,,,,,,,,,,99.0,99.0,99.0*00\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .GNSS_DOP(PDOP, HDOP, VDOP, auto3D, solution, ids) = payload else {
                    fail("expected .GNSS_DOP, got \(payload)")
                    return
                }

                expect(PDOP).to(equal(99.0))
                expect(HDOP).to(equal(99.0))
                expect(VDOP).to(equal(99.0))
                expect(auto3D).to(beTrue())
                expect(solution).to(equal(GNSS.SolutionType.none))
                expect(ids).to(beEmpty())
            }
        }
    }
}
