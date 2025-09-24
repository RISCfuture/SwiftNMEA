import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class EVESpec: AsyncSpec {
  override static func spec() {
    describe("8.3.29 EVE") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -33)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .waterLevelDetection,
          format: .event,
          fields: [
            hmsFractionFormatter.string(from: time),
            "COC", "Change of command"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .event(let actualTime, let tag, let description) = payload else {
          fail("expected .event, got \(payload)")
          return
        }

        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(tag).to(equal("COC"))
        expect(description).to(equal("Change of command"))
      }
    }
  }
}
