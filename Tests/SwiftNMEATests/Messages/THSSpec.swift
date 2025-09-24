import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class THSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.79 THS") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .gyroCompass,
          format: .trueHeadingMode,
          fields: [123.4, "A"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .trueHeadingMode(let heading, let mode) = payload else {
          fail("expected .trueHeading, got \(payload)")
          return
        }

        expect(heading.angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(heading.reference).to(equal(.true))
        expect(mode).to(equal(.autonomous))
      }
    }
  }
}
