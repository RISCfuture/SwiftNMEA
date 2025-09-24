import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GFASpec: AsyncSpec {
  override static func spec() {
    describe("8.3.34 GFA") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -23)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .GNSSAccuracyIntegrity,
          fields: [
            hmsFractionFormatter.string(from: time),
            1.2, 3.4, 0.5, 0.75, 12.3, 0.6, 5.0, "VSC"
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
          case .GNSSAccuracyIntegrity(
            let actualTime,
            let HPL,
            let VPL,
            let semimajorStddev,
            let semiminorStddev,
            let semimajorErrorOrientation,
            let altitudeStddev,
            let selectedAccuracy,
            let integrity
          ) =
            payload
        else {
          fail("expected .GNSSAccuracyIntegrity, got \(payload)")
          return
        }

        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(HPL).to(equal(.init(value: 1.2, unit: .meters)))
        expect(VPL).to(equal(.init(value: 3.4, unit: .meters)))
        expect(semimajorStddev).to(equal(.init(value: 0.5, unit: .meters)))
        expect(semiminorStddev).to(equal(.init(value: 0.75, unit: .meters)))
        expect(semimajorErrorOrientation.angle).to(equal(.init(value: 12.3, unit: .degrees)))
        expect(semimajorErrorOrientation.reference).to(equal(.true))
        expect(altitudeStddev).to(equal(.init(value: 0.6, unit: .meters)))
        expect(selectedAccuracy).to(equal(.init(value: 5.0, unit: .meters)))
        expect(integrity).to(equal([.RAIM: .notInUse, .SBAS: .safe, .GIC: .caution]))
      }
    }
  }
}
