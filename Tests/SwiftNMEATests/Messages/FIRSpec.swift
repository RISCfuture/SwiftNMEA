import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.36 FIR")
struct FIRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .fireDetection,
      format: .fireDetection,
      fields: [
        "E", hmsFractionFormatter.string(from: time),
        "FS", "AB", 12, 2,
        "A", "V", "GALLEY"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .fireDetection(
        type,
        actualTime,
        detector,
        zone,
        loop,
        number,
        condition,
        isAcknowledged,
        description
      ) = payload
    else {
      Issue.record("expected .fireDetection, got \(payload)")
      return
    }

    #expect(type == .event)
    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(detector == .smoke)
    #expect(zone == "AB")
    #expect(loop == 12)
    #expect(number == 2)
    #expect(condition == .activation)
    #expect(isAcknowledged == false)
    #expect(description == "GALLEY")
  }
}
