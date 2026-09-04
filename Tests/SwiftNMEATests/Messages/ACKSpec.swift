import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.6 ACK` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .navWatchAlarm,
      format: .alarmAcknowledgement,
      fields: [123]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .alarmAcknowledgement(identifier: 123))
  }
}
