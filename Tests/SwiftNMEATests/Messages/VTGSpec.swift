import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VTGSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.98 VTG") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .groundSpeedCourse,
          fields: [
            123.4, "T", 124.5, "M",
            12.3, "N", 23.4, "K",
            "A"
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
          case .groundSpeedCourse(
            let courseTrue,
            let courseMagnetic,
            let speedKnots,
            let speedKph,
            let mode
          ) = payload
        else {
          fail("expected .groundSpeedCourse, got \(payload)")
          return
        }

        expect(courseTrue.angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(courseTrue.reference).to(equal(.true))
        expect(courseMagnetic.angle).to(equal(.init(value: 124.5, unit: .degrees)))
        expect(courseMagnetic.reference).to(equal(.magnetic))
        expect(speedKnots).to(equal(.init(value: 12.3, unit: .knots)))
        expect(speedKph).to(equal(.init(value: 23.4, unit: .kilometersPerHour)))
        expect(mode).to(equal(.autonomous))
      }
    }
  }
}
