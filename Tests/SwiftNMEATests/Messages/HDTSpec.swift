import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.52 HDT")
struct HDTTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .magneticCompass,
      format: .trueHeading,
      fields: [190.1, "T"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case .trueHeading(let heading) = payload else {
      Issue.record("expected .trueHeading, got \(payload)")
      return
    }

    #expect(heading.angle == .init(value: 190.1, unit: .degrees))
    #expect(heading.reference == .true)
  }
}
