import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HBTSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.42 HBT") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .transducer,
          format: .heartbeat,
          fields: ["0.5", "A", 8]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .heartbeat(let interval, let isNormal, let sequenceNumber) = payload else {
          fail("expected .heartbeat, got \(payload)")
          return
        }

        expect(interval).to(equal(.init(value: 0.5, unit: .seconds)))
        expect(isNormal).to(beTrue())
        expect(sequenceNumber).to(equal(8))
      }
    }
  }
}
