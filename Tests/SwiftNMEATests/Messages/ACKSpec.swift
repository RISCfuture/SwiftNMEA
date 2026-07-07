import Testing

@testable import SwiftNMEA

@Suite("8.3.6 ACK")
struct ACKTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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
