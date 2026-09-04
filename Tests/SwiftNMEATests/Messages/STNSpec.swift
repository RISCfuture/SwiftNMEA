import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.100 STN` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .talkerID,
      fields: [12]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .talkerID(12))
  }
}
