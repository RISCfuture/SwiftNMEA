import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HTDSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.49 HTD") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric, talker: .autopilotGeneral, format: .headingControlData,
          fields: [
            "A", 5.5, "L",
            "R", "T",
            6.5, 2.0, 0.5, 1.5,
            180.1, 0.25, 190.5, "M",
            "A", "V", "A", 185.2,
          ])
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .headingControlData(
            let heading, let track, let rudderAngle, let override, let mode, let turnMode,
            let rudderLimit, let headingLimit, let trackLimit, let radius, let rate,
            let rudderLimitExceeded, let offHeading, let offTrack, let currentHeading) = payload
        else {
          fail("expected .headingControlCommand, got \(payload)")
          return
        }

        expect(heading!.angle).to(equal(.init(value: 180.1, unit: .degrees)))
        expect(heading!.reference).to(equal(.magnetic))
        expect(track!.angle).to(equal(.init(value: 190.5, unit: .degrees)))
        expect(track!.reference).to(equal(.magnetic))
        expect(rudderAngle).to(equal(.init(value: -5.5, unit: .degrees)))
        expect(override).to(beTrue())
        expect(mode).to(equal(.rudderControl))
        expect(turnMode).to(equal(.rate))
        expect(rudderLimit).to(equal(.init(value: 6.5, unit: .degrees)))
        expect(headingLimit).to(equal(.init(value: 2.0, unit: .degrees)))
        expect(trackLimit).to(equal(.init(value: 0.25, unit: .nauticalMiles)))
        expect(radius).to(equal(.init(value: 0.5, unit: .nauticalMiles)))
        expect(rate).to(equal(.init(value: 1.5, unit: .degreesPerMinute)))
        expect(rudderLimitExceeded).to(beFalse())
        expect(offHeading).to(beTrue())
        expect(offTrack).to(beFalse())
        expect(currentHeading.angle).to(equal(.init(value: 185.2, unit: .degrees)))
        expect(currentHeading.reference).to(equal(.magnetic))
      }
    }
  }
}
