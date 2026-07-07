import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.28 DPT")
struct DPTTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .depth,
      fields: [1.2, -2.3, 40.0]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .depth(depth, offset, maxRange) = payload else {
      Issue.record("expected .depth, got \(payload)")
      return
    }

    #expect(depth == .init(value: 1.2, unit: .meters))
    #expect(offset == .init(value: -2.3, unit: .meters))
    #expect(maxRange == .init(value: 40.0, unit: .meters))
  }
}
