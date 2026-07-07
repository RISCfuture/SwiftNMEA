import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.11 AKD")
struct AKDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -150)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .detailAlarmAcknowledgement,
      fields: [
        hmsFractionFormatter.string(from: time),
        "SG", "PU", 1, 2, "SG", nil, 1
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .detailAlarmAcknowledgement(
        actualTime,
        alarm,
        instance,
        sender,
        senderInstance
      ) = payload
    else {
      Issue.record("expected .detailAlarmAcknowledgement, got \(payload)")
      return
    }
    #expect(abs(try #require(actualTime).timeIntervalSince(time)) < 0.01)
    #expect(alarm == .steeringGear(subsystem: .powerUnit(type: .powerFail)))
    #expect(instance == 1)
    #expect(sender == .steeringGear(subsystem: nil))
    #expect(senderInstance == 1)
  }
}
