import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HSCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.47 HSC") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .headingSteeringCommand,
          fields: [12.3, "T", 23.4, "M", "C"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .headingSteeringCommand(let headingTrue, let headingMagnetic, let status) = payload
        else {
          fail("expected .headingSteeringCommand, got \(payload)")
          return
        }

        expect(headingTrue.angle).to(equal(.init(value: 12.3, unit: .degrees)))
        expect(headingTrue.reference).to(equal(.true))
        expect(headingMagnetic.angle).to(equal(.init(value: 23.4, unit: .degrees)))
        expect(headingMagnetic.reference).to(equal(.magnetic))
        expect(status).to(equal(.command))
      }
    }
  }
}
