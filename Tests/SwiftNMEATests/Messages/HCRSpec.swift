import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class HCRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.50 HCR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .gyroCompass,
          format: .headingCorrectionReport,
          fields: [123.4, "A", "A", -12.3]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .headingCorrectionReport(heading, mode, correctionState, correctionValue) =
            payload
        else {
          fail("expected .headingCorrectionReport, got \(payload)")
          return
        }

        expect(heading.angle).to(equal(.init(value: 123.4, unit: .degrees)))
        expect(heading.reference).to(equal(.true))
        expect(mode).to(equal(.autonomous))
        expect(correctionState).to(equal(.speedLatitudeAndDynamic))
        expect(correctionValue).to(equal(.init(value: -12.3, unit: .degrees)))
      }

      it("parses a sentence with no correction value") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .gyroCompass,
          format: .headingCorrectionReport,
          fields: [200.0, "M", "N", nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .headingCorrectionReport(heading, mode, correctionState, correctionValue) =
            payload
        else {
          fail("expected .headingCorrectionReport, got \(payload)")
          return
        }

        expect(heading.angle).to(equal(.init(value: 200.0, unit: .degrees)))
        expect(mode).to(equal(.manual))
        expect(correctionState).to(equal(.noCorrection))
        expect(correctionValue).to(beNil())
      }

      it("throws an error for an invalid mode indicator") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .gyroCompass,
          format: .headingCorrectionReport,
          fields: [123.4, "X", "A", 0.0]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
