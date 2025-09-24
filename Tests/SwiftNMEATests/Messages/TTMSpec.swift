import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class TTMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.85 TTM") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -10)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .radar,
          format: .trackedTarget,
          fields: [
            12,
            12.3, 234.5, "T", 15.5, 110.1, "R",
            45.6, 10.7, "K",
            "TGT1", "T", "R", hmsFractionFormatter.string(from: time), "A"
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
          case .trackedTarget(
            let number,
            let distance,
            let bearing,
            let speed,
            let course,
            let CPADistance,
            let CPATime,
            let name,
            let status,
            let isReference,
            let actualTime,
            let acquisition
          ) =
            payload
        else {
          fail("expected .trackedTarget, got \(payload)")
          return
        }

        expect(number).to(equal(12))
        expect(distance).to(equal(.init(value: 12.3, unit: .kilometers)))
        expect(bearing.angle).to(equal(.init(value: 234.5, unit: .degrees)))
        expect(bearing.reference).to(equal(.true))
        expect(speed).to(equal(.init(value: 15.5, unit: .kilometersPerHour)))
        expect(course.angle).to(equal(.init(value: 110.1, unit: .degrees)))
        expect(course.reference).to(equal(.relative))
        expect(CPADistance).to(equal(.init(value: 45.6, unit: .kilometers)))
        expect(CPATime).to(equal(.init(value: 10.7, unit: .minutes)))
        expect(name).to(equal("TGT1"))
        expect(status).to(equal(.tracking))
        expect(isReference).to(beTrue())
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(acquisition).to(equal(.automatic))
      }
    }
  }
}
