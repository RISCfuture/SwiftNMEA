import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VDRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.92 VDR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .depthSounder,
          format: .currentSetDrift,
          fields: [123.4, "T", 124.5, "M", 12.3, "N"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .currentSetDrift(let setTrue, let setMagnetic, let drift) = payload else {
          fail("expected .currentSetDrift, got \(payload)")
          return
        }

        expect(setTrue.angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(setTrue.reference).to(equal(.true))
        expect(setMagnetic.angle).to(equal(.init(value: 124.5, unit: .degrees)))
        expect(setMagnetic.reference).to(equal(.magnetic))
        expect(drift).to(equal(.init(value: 12.3, unit: .knots)))
      }
    }
  }
}
