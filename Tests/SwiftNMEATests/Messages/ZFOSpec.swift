import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ZFOSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.108 ZFO") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -1)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .radar,
          format: .timeFromOrigin,
          fields: [hmsFractionFormatter.string(from: time), "010203.04", "KOAK"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .timeFromOrigin(let observation, let elapsedTime, let originID) = payload else {
          fail("expected .timeFromOrigin, got \(payload)")
          return
        }

        expect(observation).to(beCloseTo(time, within: 0.01))
        expect(elapsedTime).to(equal(.seconds(3723) + .milliseconds(40)))
        expect(originID).to(equal("KOAK"))
      }
    }
  }
}
