import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class FIRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.30 FIR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -10)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .fireDetection,
          format: .fireDetection,
          fields: [
            "E", hmsFractionFormatter.string(from: time),
            "FS", "AB", 12, 2,
            "A", "V", "GALLEY"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .fireDetection(
            let type,
            let actualTime,
            let detector,
            let zone,
            let loop,
            let number,
            let condition,
            let isAcknowledged,
            let description
          ) = payload
        else {
          fail("expected .fireDetection, got \(payload)")
          return
        }

        expect(type).to(equal(.event))
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(detector).to(equal(.smoke))
        expect(zone).to(equal("AB"))
        expect(loop).to(equal(12))
        expect(number).to(equal(2))
        expect(condition).to(equal(.activation))
        expect(isAcknowledged).to(beFalse())
        expect(description).to(equal("GALLEY"))
      }
    }
  }
}
