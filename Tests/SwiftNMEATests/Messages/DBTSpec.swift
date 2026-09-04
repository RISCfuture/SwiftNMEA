import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.25 DBT` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .depthBelowTransducer,
      fields: [60, "f", 18.29, "M", 10, "F"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .depthBelowTransducer([
          .init(value: 60, unit: .feet),
          .init(value: 18.29, unit: .meters),
          .init(value: 10, unit: .fathoms)
        ])
    )
  }
}
