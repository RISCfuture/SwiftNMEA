import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class MSKSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.56 MSK") {
      it("parses the example from the spec") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(to: "$CRMSK,293.0,M,100,A,,10,C")
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .MSKReceiverInterface(
            let frequency,
            let bitRate,
            let statusInterval,
            let channel,
            let status
          ) = payload
        else {
          fail("expected .MSKReceiverInterface, got \(payload)")
          return
        }

        expect(frequency).to(equal(.manual(.init(value: 293, unit: .kilohertz))))
        expect(bitRate).to(equal(.auto(.init(value: 100, unit: .bitsPerSecond))))
        expect(statusInterval).to(beNil())
        expect(channel).to(equal(10))
        expect(status).to(equal(.command))
      }
    }
  }
}
