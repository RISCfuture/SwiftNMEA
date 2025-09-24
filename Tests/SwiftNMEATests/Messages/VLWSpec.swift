import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VLWSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.95 VLW") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .distanceData,
          fields: [123.4, "N", 12.3, "N", 124.5, "N", 12.4, "N"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .distanceData(
            let waterCumulative,
            let waterSinceReset,
            let groundCumulative,
            let groundSinceReset
          ) =
            payload
        else {
          fail("expected .distanceData, got \(payload)")
          return
        }

        expect(waterCumulative).to(equal(.init(value: 123.4, unit: .nauticalMiles)))
        expect(waterSinceReset).to(equal(.init(value: 12.3, unit: .nauticalMiles)))
        expect(groundCumulative).to(equal(.init(value: 124.5, unit: .nauticalMiles)))
        expect(groundSinceReset).to(equal(.init(value: 12.4, unit: .nauticalMiles)))
      }
    }
  }
}
