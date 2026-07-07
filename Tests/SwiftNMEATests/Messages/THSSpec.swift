import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.101 THS")
struct THSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .gyroCompass,
      format: .trueHeadingMode,
      fields: [123.4, "A"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .trueHeadingMode(heading, mode) = payload else {
      Issue.record("expected .trueHeading, got \(payload)")
      return
    }

    #expect(heading.angle == .init(value: 123.4, unit: .degrees))
    #expect(heading.reference == .true)
    #expect(mode == .autonomous)
  }
}
