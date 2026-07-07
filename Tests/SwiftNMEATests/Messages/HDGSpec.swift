import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.51 HDG")
struct HDGTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .magneticCompass,
      format: .heading,
      fields: [1.1, 2.2, "W", 3.3, "E"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .heading(heading, deviation, variation) = payload else {
      Issue.record("expected .heading, got \(payload)")
      return
    }

    #expect(heading.angle == .init(value: 1.1, unit: .degrees))
    #expect(heading.reference == .magnetic)
    #expect(deviation == .init(value: -2.2, unit: .degrees))
    #expect(variation == .init(value: 3.3, unit: .degrees))
  }
}
