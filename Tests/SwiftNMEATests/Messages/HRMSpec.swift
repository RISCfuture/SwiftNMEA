import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HRMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.55 HRM") {
      it("parses a sentence with all values") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .heelRollMeasurement,
          fields: [-2.5, 8.0, 5.0, 6.0, "A", 7.0, 9.0, "123456", 15, 6, 2024, 30.0, "R"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .heelRollMeasurement(
            heelAngle,
            rollPeriod,
            rollAmplitudePort,
            rollAmplitudeStarboard,
            isValid,
            peakHoldPort,
            peakHoldStarboard,
            peakHoldResetTime,
            alertThreshold,
            status
          ) = payload
        else {
          fail("expected .heelRollMeasurement, got \(payload)")
          return
        }

        expect(heelAngle).to(equal(.init(value: -2.5, unit: .degrees)))
        expect(rollPeriod).to(equal(.init(value: 8.0, unit: .seconds)))
        expect(rollAmplitudePort).to(equal(.init(value: 5.0, unit: .degrees)))
        expect(rollAmplitudeStarboard).to(equal(.init(value: 6.0, unit: .degrees)))
        expect(isValid).to(beTrue())
        expect(peakHoldPort).to(equal(.init(value: 7.0, unit: .degrees)))
        expect(peakHoldStarboard).to(equal(.init(value: 9.0, unit: .degrees)))
        expect(alertThreshold).to(equal(.init(value: 30.0, unit: .degrees)))
        expect(status).to(equal(.reply))

        let expectedReset = calendar.date(
          from: .init(
            timeZone: .gmt,
            year: 2024,
            month: 6,
            day: 15,
            hour: 12,
            minute: 34,
            second: 56
          )
        )
        expect(peakHoldResetTime).to(equal(expectedReset))
      }

      it("parses a sentence with unavailable peak hold values") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .heelRollMeasurement,
          fields: [-2.5, 8.0, 5.0, 6.0, "A", nil, nil, nil, nil, nil, nil, nil, "R"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .heelRollMeasurement(
            _,
            _,
            _,
            _,
            _,
            peakHoldPort,
            peakHoldStarboard,
            peakHoldResetTime,
            alertThreshold,
            _
          ) = payload
        else {
          fail("expected .heelRollMeasurement, got \(payload)")
          return
        }

        expect(peakHoldPort).to(beNil())
        expect(peakHoldStarboard).to(beNil())
        expect(peakHoldResetTime).to(beNil())
        expect(alertThreshold).to(beNil())
      }

      it("throws when the sentence status flag is missing") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .heelRollMeasurement,
          fields: [-2.5, 8.0, 5.0, 6.0, "A", nil, nil, nil, nil, nil, nil, nil, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
      }
    }
  }
}
