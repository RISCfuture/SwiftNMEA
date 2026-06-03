import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class RSASpec: AsyncSpec {
  override static func spec() {
    describe("8.3.86 RSA") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .rudderSensorAngle,
          fields: [1.2, "A", -2.3, "V", 3.4, "A", -4.5, "V"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .rudderSensorAngle(
            starboard,
            port,
            starboardValid,
            portValid,
            center,
            centerValid,
            bowOrOther,
            bowOrOtherValid
          ) = payload
        else {
          fail("expected .rudderSensorAngle, got \(payload)")
          return
        }

        expect(starboard).to(equal(1.2))
        expect(starboardValid).to(beTrue())
        expect(port).to(equal(-2.3))
        expect(portValid).to(beFalse())
        expect(center).to(equal(3.4))
        expect(centerValid).to(beTrue())
        expect(bowOrOther).to(equal(-4.5))
        expect(bowOrOtherValid).to(beFalse())
      }

      it("throws when a rudder sensor has no corresponding status") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .rudderSensorAngle,
          fields: [1.2, nil, -2.3, "V", nil, nil, nil, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
        expect(error.fieldNumber).to(equal(1))
      }
    }
  }
}
