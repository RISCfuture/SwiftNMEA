import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.50 HCR")
struct HCRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .gyroCompass,
      format: .headingCorrectionReport,
      fields: [123.4, "A", "A", -12.3]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .headingCorrectionReport(heading, mode, correctionState, correctionValue) =
        payload
    else {
      Issue.record("expected .headingCorrectionReport, got \(payload)")
      return
    }

    #expect(heading.angle == .init(value: 123.4, unit: .degrees))
    #expect(heading.reference == .true)
    #expect(mode == .autonomous)
    #expect(correctionState == .speedLatitudeAndDynamic)
    #expect(correctionValue == .init(value: -12.3, unit: .degrees))
  }

  @Test("parses a sentence with no correction value")
  func parsesASentenceWithNoCorrectionValue() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .gyroCompass,
      format: .headingCorrectionReport,
      fields: [200.0, "M", "N", nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .headingCorrectionReport(heading, mode, correctionState, correctionValue) =
        payload
    else {
      Issue.record("expected .headingCorrectionReport, got \(payload)")
      return
    }

    #expect(heading.angle == .init(value: 200.0, unit: .degrees))
    #expect(mode == .manual)
    #expect(correctionState == .noCorrection)
    #expect(correctionValue == nil)
  }

  @Test("throws an error for an invalid mode indicator")
  func throwsAnErrorForAnInvalidModeIndicator() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .gyroCompass,
      format: .headingCorrectionReport,
      fields: [123.4, "X", "A", 0.0]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
