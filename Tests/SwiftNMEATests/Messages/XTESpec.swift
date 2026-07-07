import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.128 XTE")
struct XTETests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .crossTrackError,
      fields: [
        "A", "V",
        12.3, "L", "N",
        "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .crossTrackError(
        error,
        mode,
        LORANC_blinkSNRFlag,
        LORANC_cycleLockWarningFlag
      ) = payload
    else {
      Issue.record("expected .crossTrackError, got \(payload)")
      return
    }

    #expect(error == .init(value: -12.3, unit: .nauticalMiles))
    #expect(mode == .autonomous)
    #expect(!LORANC_blinkSNRFlag)
    #expect(LORANC_cycleLockWarningFlag)
  }
}
