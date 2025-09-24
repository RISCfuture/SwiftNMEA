import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VPWSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.96 VPW") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .speedParallelToWind,
          fields: [12.3, "N", 23.4, "M"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .speedParallelToWind(let knots, let mps) = payload else {
          fail("expected .speedMadeGood, got \(payload)")
          return
        }

        expect(knots).to(equal(.init(value: 12.3, unit: .knots)))
        expect(mps).to(equal(.init(value: 23.4, unit: .metersPerSecond)))
      }
    }
  }
}
