import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ALASpec: AsyncSpec {
  override static func spec() {
    describe("8.3.10 ALA") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -2000)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .detailAlarm,
          fields: [
            hmsFractionFormatter.string(from: time),
            "SG", nil, 3, 900, "H", "V", "example alarm"
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
          case .detailAlarm(
            let actualTime,
            let alarm,
            let instance,
            let condition,
            let state,
            let description
          ) =
            payload
        else {
          fail("expected .detailAlarm, got \(payload)")
          return
        }
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(alarm).to(equal(.steeringGear(subsystem: .none(code: 900))))
        expect(instance).to(equal(3))
        expect(condition).to(equal(.high))
        expect(state).to(equal(.notAcknowledged))
        expect(description).to(equal("example alarm"))
      }
    }
  }
}
