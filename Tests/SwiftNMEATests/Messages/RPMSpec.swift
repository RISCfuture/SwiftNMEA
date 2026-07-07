import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.84 RPM")
struct RPMTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .propulsion,
      format: .revolutions,
      fields: ["S", 0, 1.2, -2.3, "A"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .revolutions(source, number, speed, pitch, isValid) = payload
    else {
      Issue.record("expected .revolutions, got \(payload)")
      return
    }

    #expect(source == .shaft)
    #expect(number == 0)
    #expect(speed == .init(value: 1.2, unit: .revolutionsPerMinute))
    #expect(pitch == -2.3)
    #expect(isValid)
  }
}
