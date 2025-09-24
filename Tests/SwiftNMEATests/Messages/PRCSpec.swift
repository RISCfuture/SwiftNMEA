import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class PRCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.66 PRC") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .propulsion,
          format: .propulsionRemoteControl,
          fields: [
            50.0, "A",
            2250.0, "R",
            13.0, "D",
            "B", 0
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .propulsionRemoteControl(
            let leverDemandPosition,
            let leverDemandValid,
            let RPMDemand,
            let pitchDemand,
            let location,
            let engineNumber
          ) = payload
        else {
          fail("expected .propulsionRemoteControl, got \(payload)")
          return
        }

        expect(leverDemandPosition).to(equal(50))
        expect(leverDemandValid).to(beTrue())
        expect(RPMDemand).to(equal(.value(.init(value: 2250, unit: .revolutionsPerMinute))))
        expect(pitchDemand).to(equal(.value(.init(value: 13, unit: .degrees))))
        expect(location).to(equal(.bridge))
        expect(engineNumber).to(equal(0))
      }
    }
  }
}
