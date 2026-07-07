import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.69 MWV")
struct MWVTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commDataReceiver,
      format: .windAngleSpeed,
      fields: [123.4, "R", 7.0, "K", "A"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .windAngleSpeed(angle, speed, reference, isValid) = payload
    else {
      Issue.record("expected .windAngleSpeed, got \(payload)")
      return
    }

    #expect(angle == .init(value: 123.4, unit: .degrees))
    #expect(reference == .relative)
    #expect(speed == .init(value: 7, unit: .kilometersPerHour))
    #expect(isValid)
  }
}
