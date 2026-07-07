import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.15 ALR")
struct ALRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -1500)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .alarmState,
      fields: [
        hmsFractionFormatter.string(from: time),
        123, "A", "V", "test alarm"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .alarmState(
        changeTime,
        identifier,
        thresholdExceeded,
        acknowledged,
        description
      ) = payload
    else {
      Issue.record("expected .alarmState, got \(payload)")
      return
    }
    #expect(abs(changeTime.timeIntervalSince(time)) < 0.01)
    #expect(identifier == 123)
    #expect(thresholdExceeded)
    #expect(!acknowledged)
    #expect(description == "test alarm")
  }
}
