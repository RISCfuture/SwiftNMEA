import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class APBSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.12 APB") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .autopilotSentenceB,
          fields: [
            "A", "V",
            12.3, "L", "N",
            "V", "A",
            101.0, "T",
            "KOAK",
            123.0, "T",
            5.5, "M",
            "D"
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
          case .autopilotSentenceB(
            let LORANC_blinkSNRFlag,
            let LORANC_cycleLockWarningFlag,
            let crossTrackError,
            let arrivalCircleEntered,
            let perpendicularPassed,
            let bearingOriginToDest,
            let destinationID,
            let bearingPresentPosToDest,
            let headingToDest,
            let mode
          ) = payload
        else {
          fail("expected .autopilotSentenceB, got \(payload)")
          return
        }

        expect(LORANC_blinkSNRFlag).to(equal(false))
        expect(LORANC_cycleLockWarningFlag).to(equal(true))
        expect(crossTrackError).to(equal(.init(value: -12.3, unit: .nauticalMiles)))
        expect(arrivalCircleEntered).to(equal(false))
        expect(perpendicularPassed).to(equal(true))
        expect(bearingOriginToDest).to(equal(.init(degrees: 101.0, reference: .true)))
        expect(destinationID).to(equal("KOAK"))
        expect(bearingPresentPosToDest).to(equal(.init(degrees: 123.0, reference: .true)))
        expect(headingToDest).to(equal(.init(degrees: 5.5, reference: .magnetic)))
        expect(mode).to(equal(.differential))
      }
    }
  }
}
