import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HMRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.45 HMR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .headingMonitorReceive,
          fields: [
            "HDG1", "HDG2",
            5.0, 6.0, "V",
            96.2, "A", "M", 6.5, "E",
            90.2, "V", "T", nil, nil,
            3.5, "W"
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
          case .headingMonitorReceive(
            let sensor1,
            let sensor2,
            let setDifference,
            let difference,
            let differenceOK,
            let variation
          ) = payload
        else {
          fail("expected .headingMonitorReceive, got \(payload)")
          return
        }

        expect(sensor1.id).to(equal("HDG1"))
        expect(sensor1.heading.angle).to(equal(.init(value: 96.2, unit: .degrees)))
        expect(sensor1.heading.reference).to(equal(.magnetic))
        expect(sensor1.deviation).to(equal(.init(value: 6.5, unit: .degrees)))
        expect(sensor1.isValid).to(beTrue())

        expect(sensor2.id).to(equal("HDG2"))
        expect(sensor2.heading.angle).to(equal(.init(value: 90.2, unit: .degrees)))
        expect(sensor2.heading.reference).to(equal(.true))
        expect(sensor2.deviation).to(beNil())
        expect(sensor2.isValid).to(beFalse())

        expect(setDifference).to(equal(.init(value: 5.0, unit: .degrees)))
        expect(difference).to(equal(.init(value: 6.0, unit: .degrees)))
        expect(differenceOK).to(beFalse())
        expect(variation).to(equal(.init(value: -3.5, unit: .degrees)))
      }
    }
  }
}
