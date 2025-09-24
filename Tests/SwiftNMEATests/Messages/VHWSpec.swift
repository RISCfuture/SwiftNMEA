import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VHWSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.94 VHW") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .waterSpeedHeading,
          fields: [123.4, "T", 124.5, "M", 12.3, "N", 23.4, "K"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .waterSpeedHeading(let bearingTrue, let magnetic, let speedKnots, let speedKph) =
            payload
        else {
          fail("expected .waterSpeedHeading, got \(payload)")
          return
        }

        expect(bearingTrue.angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(bearingTrue.reference).to(equal(.true))
        expect(magnetic.angle).to(equal(.init(value: 124.5, unit: .degrees)))
        expect(magnetic.reference).to(equal(.magnetic))
        expect(speedKnots).to(equal(.init(value: 12.3, unit: .knots)))
        expect(speedKph).to(equal(.init(value: 23.4, unit: .kilometersPerHour)))
      }
    }
  }
}
