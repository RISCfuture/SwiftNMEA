import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class MSSSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.57 MSS") {
            it("parses the example from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$CRMSS,50,17,293.0,100,1*55\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .MSKReceiverSignalStatus(signalStrength, SNR, frequency, bitRate, channel) = payload else {
                    fail("expected .MSKReceiverSignalStatus, got \(payload)")
                    return
                }

                expect(signalStrength).to(equal(50))
                expect(SNR).to(equal(17))
                expect(frequency).to(equal(.init(value: 293.0, unit: .kilohertz)))
                expect(bitRate).to(equal(.init(value: 100, unit: .bitsPerSecond)))
                expect(channel).to(equal(1))
            }
        }
    }
}
