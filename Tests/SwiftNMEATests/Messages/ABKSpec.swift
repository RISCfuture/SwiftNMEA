import Testing

@testable import SwiftNMEA

@Suite("8.3.3 ABK")
struct ABKTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISBroadcastAcknowledgement,
      fields: [123_456_789, "A", "6.1", 3, 1]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .AISBroadcastAcknowledgement(
          MMSI: 123_456_789,
          channel: .A,
          messageID: "6.1",
          sequence: 3,
          type: .noAck
        )
    )
  }
}
