import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.124 WCV")
struct WCVTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .waypointClosure,
      fields: [12.3, "N", "KSQL", "D"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .waypointClosure(closure, identifier, mode) = payload else {
      Issue.record("expected .waypointClosure, got \(payload)")
      return
    }

    #expect(closure == .init(value: 12.3, unit: .knots))
    #expect(identifier == "KSQL")
    #expect(mode == .differential)
  }
}
