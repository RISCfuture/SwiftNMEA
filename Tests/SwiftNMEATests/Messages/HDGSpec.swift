import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HDGSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.43 HDG") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .magneticCompass,
          format: .heading,
          fields: [1.1, 2.2, "W", 3.3, "E"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .heading(let heading, let deviation, let variation) = payload else {
          fail("expected .heading, got \(payload)")
          return
        }

        expect(heading.angle).to(equal(.init(value: 1.1, unit: .degrees)))
        expect(heading.reference).to(equal(.magnetic))
        expect(deviation).to(equal(.init(value: -2.2, unit: .degrees)))
        expect(variation).to(equal(.init(value: 3.3, unit: .degrees)))
      }
    }
  }
}
