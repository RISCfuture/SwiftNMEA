import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class MWDSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.59 MWD") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commDataReceiver,
          format: .windDirectionSpeed,
          fields: [
            225.0, "T", 220.0, "M",
            12.5, "N", 6.43, "M"
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
          case .windDirectionSpeed(
            let directionTrue,
            let directionMagnetic,
            let speedKnots,
            let speedMps
          ) = payload
        else {
          fail("expected .windDirectionSpeed, got \(payload)")
          return
        }

        expect(directionTrue.angle).to(equal(.init(value: 225.0, unit: .degrees)))
        expect(directionTrue.reference).to(equal(.true))
        expect(directionMagnetic.angle).to(equal(.init(value: 220.0, unit: .degrees)))
        expect(directionMagnetic.reference).to(equal(.magnetic))
        expect(speedKnots).to(equal(.init(value: 12.5, unit: .knots)))
        expect(speedMps).to(equal(.init(value: 6.43, unit: .metersPerSecond)))
      }
    }
  }
}
