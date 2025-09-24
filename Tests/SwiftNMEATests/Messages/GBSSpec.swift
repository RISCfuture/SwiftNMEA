import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GBSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.32 GBS") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -10)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GPS,
          format: .GNSSFaultDetection,
          fields: [
            hmsFractionFormatter.string(from: time), 1.2, 3.4, 5.6,
            35, 0.5, 1.5, 0.75,
            1, 5
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
          case .GNSSFaultDetection(
            let actualTime,
            let latitudeError,
            let longitudeError,
            let altitudeError,
            let failedSatellite,
            let missProbability,
            let biasEstimate,
            let biasEstimateStddev
          ) =
            payload
        else {
          fail("expected .GNSSFaultDetection, got \(payload)")
          return
        }

        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(latitudeError).to(equal(.init(value: 1.2, unit: .meters)))
        expect(longitudeError).to(equal(.init(value: 3.4, unit: .meters)))
        expect(altitudeError).to(equal(.init(value: 5.6, unit: .meters)))

        expect(failedSatellite.PRN).to(equal(122))
        expect(failedSatellite.isAugmented).to(beTrue())
        guard case .GPS(let id, let signal) = failedSatellite else {
          fail("expected .GPS, got \(failedSatellite)")
          return
        }
        expect(id).to(equal(35))
        expect(signal).to(equal(.L2C_M))

        expect(missProbability).to(equal(0.5))
        expect(biasEstimate).to(equal(.init(value: 1.5, unit: .meters)))
        expect(biasEstimateStddev).to(equal(.init(value: 0.75, unit: .meters)))
      }
    }
  }
}
