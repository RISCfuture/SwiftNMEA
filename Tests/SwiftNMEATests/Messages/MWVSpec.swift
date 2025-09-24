import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class MWVSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.60 MWV") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commDataReceiver,
          format: .windAngleSpeed,
          fields: [123.4, "R", 7.0, "K", "A"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .windAngleSpeed(let angle, let speed, let reference, let isValid) = payload
        else {
          fail("expected .windAngleSpeed, got \(payload)")
          return
        }

        expect(angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(reference).to(equal(.relative))
        expect(speed).to(equal(.init(value: 7, unit: .kilometersPerHour)))
        expect(isValid).to(beTrue())
      }
    }
  }
}
