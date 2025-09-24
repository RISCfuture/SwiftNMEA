import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HMSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.46 HMS") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .headingMonitorSet,
          fields: ["HDG1", "HDG2", 5.0]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .headingMonitorSet(let sensor1, let sensor2, let maxDiff) = payload else {
          fail("expected .headingMonitorSet, got \(payload)")
          return
        }

        expect(sensor1).to(equal("HDG1"))
        expect(sensor2).to(equal("HDG2"))
        expect(maxDiff).to(equal(.init(value: 5.0, unit: .degrees)))
      }
    }
  }
}
