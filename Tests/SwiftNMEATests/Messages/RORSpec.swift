import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class RORSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.70 ROR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .rudderOrder,
          fields: [1.2, "A", -2.3, "V", "W"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .rudderOrder(
            let starboard,
            let port,
            let starboardValid,
            let portValid,
            let commandSource
          ) = payload
        else {
          fail("expected .rudderOrder, got \(payload)")
          return
        }

        expect(starboard).to(equal(1.2))
        expect(starboardValid).to(beTrue())
        expect(port).to(equal(-2.3))
        expect(portValid).to(beFalse())
        expect(commandSource).to(equal(.wing))
      }
    }
  }
}
