import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.123 WAT")
struct WATTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -15)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .waterLevel,
      fields: [
        "E", hmsFractionFormatter.string(from: time),
        "WL", "CA", "01", 3,
        "H", "O", "Detector CA01"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .waterLevel(
        messageType,
        actualTime,
        systemType,
        location1,
        location2,
        number,
        alarmCondition,
        isOverriden,
        description
      ) = payload
    else {
      Issue.record("expected .waterLevel, got \(payload)")
      return
    }

    #expect(messageType == .event)
    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(systemType == .waterLevel)
    #expect(location1 == "CA")
    #expect(location2 == "01")
    #expect(number == 3)
    #expect(alarmCondition == .alarmHigh)
    #expect(isOverriden == true)
    #expect(description == "Detector CA01")
  }
}
