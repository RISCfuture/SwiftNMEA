import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.35 EVE")
struct EVETests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -33)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .event,
      fields: [
        hmsFractionFormatter.string(from: time),
        "COC", "Change of command"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .event(actualTime, tag, description) = payload else {
      Issue.record("expected .event, got \(payload)")
      return
    }

    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(tag == "COC")
    #expect(description == "Change of command")
  }
}
