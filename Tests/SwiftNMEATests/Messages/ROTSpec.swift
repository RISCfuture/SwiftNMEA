import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ROTSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.71 ROT") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric, talker: .integratedNavigation, format: .rateOfTurn,
          fields: [-1.2, "A"])
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .rateOfTurn(let rate, let isValid) = payload else {
          fail("expected .rateOfTurn, got \(payload)")
          return
        }

        expect(rate).to(equal(.init(value: -1.2, unit: .degreesPerMinute)))
        expect(isValid).to(beTrue())
      }
    }
  }
}
