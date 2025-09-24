import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class CURSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.20 CUR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .depthSounder,
          format: .currentWaterLayer,
          fields: [
            "A", 2, 3,
            3.5,
            120.5, "R",
            11.2,
            2.0,
            99.3, "T",
            "B"
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
          case .currentWaterLayer(
            let isValid,
            let setNumber,
            let layer,
            let depth,
            let direction,
            let speed,
            let referenceDepth,
            let heading,
            let speedReference
          ) = payload
        else {
          fail("expected .currentWaterLayer, got \(payload)")
          return
        }

        expect(isValid).to(beTrue())
        expect(setNumber).to(equal(2))
        expect(layer).to(equal(3))
        expect(depth).to(equal(.init(value: 3.5, unit: .meters)))
        expect(direction).to(equal(.init(degrees: 120.5, reference: .relative)))
        expect(speed).to(equal(.init(value: 11.2, unit: .knots)))
        expect(referenceDepth).to(equal(.init(value: 2.0, unit: .meters)))
        expect(heading).to(equal(.init(degrees: 99.3, reference: .true)))
        expect(speedReference).to(equal(.bottomTrack))
      }
    }
  }
}
