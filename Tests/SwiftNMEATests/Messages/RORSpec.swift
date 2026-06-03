import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class RORSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.82 ROR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .rudderOrder,
          fields: [1.2, "A", -2.3, "V", "W", 3.4, "A", -4.5, "V"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .rudderOrder(
            starboard,
            port,
            starboardValid,
            portValid,
            commandSource,
            center,
            centerValid,
            bow,
            bowValid
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
        expect(center).to(equal(3.4))
        expect(centerValid).to(beTrue())
        expect(bow).to(equal(-4.5))
        expect(bowValid).to(beFalse())
      }

      it("throws when a rudder order has no corresponding status") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .rudderOrder,
          fields: [1.2, "A", -2.3, "V", "W", 3.4, nil, nil, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
        expect(error.fieldNumber).to(equal(6))
      }
    }
  }
}
