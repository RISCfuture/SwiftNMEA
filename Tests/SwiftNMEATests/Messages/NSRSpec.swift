import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.74 NSR")
struct NSRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .navigationStatusReport,
      fields: ["P", "A", "F", "V", "D", "A", "N", "N", "P", "A", "W", "P", "A"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .navigationStatusReport(
        headingIntegrity,
        headingPlausibility,
        positionIntegrity,
        positionPlausibility,
        STWIntegrity,
        STWPlausibility,
        SOGCOGIntegrity,
        SOGCOGPlausibility,
        depthIntegrity,
        depthPlausibility,
        STWMode,
        timeIntegrity,
        timePlausibility
      ) = payload
    else {
      Issue.record("expected .navigationStatusReport, got \(payload)")
      return
    }

    #expect(headingIntegrity == .passed)
    #expect(headingPlausibility == .plausible)
    #expect(positionIntegrity == .failed)
    #expect(positionPlausibility == .notPlausible)
    #expect(STWIntegrity == .doubtful)
    #expect(STWPlausibility == .plausible)
    #expect(SOGCOGIntegrity == .unavailable)
    #expect(SOGCOGPlausibility == .unavailable)
    #expect(depthIntegrity == .passed)
    #expect(depthPlausibility == .plausible)
    #expect(STWMode == .measured)
    #expect(timeIntegrity == .passed)
    #expect(timePlausibility == .plausible)
  }

  @Test("throws an error for an invalid integrity value")
  func throwsAnErrorForAnInvalidIntegrityValue() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .navigationStatusReport,
      fields: ["X", "A", "P", "A", "P", "A", "P", "A", "P", "A", "W", "P", "A"]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
