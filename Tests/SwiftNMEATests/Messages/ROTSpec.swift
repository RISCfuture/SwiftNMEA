import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.83 ROT")
struct ROTTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .rateOfTurn,
      fields: [-1.2, "A"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .rateOfTurn(rate, isValid) = payload else {
      Issue.record("expected .rateOfTurn, got \(payload)")
      return
    }

    #expect(rate == .init(value: -1.2, unit: .degreesPerMinute))
    #expect(isValid)
  }
}
