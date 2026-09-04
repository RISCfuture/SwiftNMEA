import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.57 HSS` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .hullStressMonitoring,
      format: .hullStress,
      fields: ["OUTER1", 1.23, "V"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .hullStress(value, point, isValid) = payload else {
      Issue.record("expected .hullStress, got \(payload)")
      return
    }

    #expect(value == 1.23)
    #expect(point == "OUTER1")
    #expect(!isValid)
  }
}
