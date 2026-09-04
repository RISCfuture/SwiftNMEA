import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.49 HBT` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .transducer,
      format: .heartbeat,
      fields: ["0.5", "A", 8]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .heartbeat(interval, isNormal, sequenceNumber) = payload else {
      Issue.record("expected .heartbeat, got \(payload)")
      return
    }

    #expect(interval == .init(value: 0.5, unit: .seconds))
    #expect(isNormal)
    #expect(sequenceNumber == 8)
  }
}
