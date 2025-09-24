import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GSTSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.40 GST") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -12)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GPS,
          format: .GNSSPseudorangeNoise,
          fields: [
            hmsFractionFormatter.string(from: time),
            1.1, 2.2, 3.3, 4.4,
            5.5, 6.6, 7.7
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
          case .GNSSPseudorangeNoise(
            let actualTime,
            let rangeStddevRMS,
            let errorSemimajorStddev,
            let errorSemiminorStddev,
            let errorOrientation,
            let errorLatitudeStddev,
            let errorLongitudeStddev,
            let errorAltitudeStddev
          ) = payload
        else {
          fail("expected .GNSSPseudorangeNoise, got \(payload)")
          return
        }

        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(rangeStddevRMS).to(equal(1.1))
        expect(errorSemimajorStddev).to(equal(.init(value: 2.2, unit: .meters)))
        expect(errorSemiminorStddev).to(equal(.init(value: 3.3, unit: .meters)))
        expect(errorOrientation).to(
          equal(.init(angle: .init(value: 4.4, unit: .degrees), reference: .true))
        )
        expect(errorLatitudeStddev).to(equal(.init(value: 5.5, unit: .meters)))
        expect(errorLongitudeStddev).to(equal(.init(value: 6.6, unit: .meters)))
        expect(errorAltitudeStddev).to(equal(.init(value: 7.7, unit: .meters)))
      }
    }
  }
}
