import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class XTRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.105 XTR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .radar,
          format: .crossTrackErrorDR,
          fields: [12.3, "L", "N"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .crossTrackErrorDR(let error) = payload else {
          fail("expected .crossTrackErrorDR, got \(payload)")
          return
        }

        expect(error).to(equal(.init(value: -12.3, unit: .nauticalMiles)))
      }
    }
  }
}
