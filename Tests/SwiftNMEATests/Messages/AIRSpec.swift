import Testing

@testable import SwiftNMEA

@Suite("8.3.10 AIR")
struct AIRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISInterrogationRequest,
      fields: [123_456_789, 1, 1, 2, nil, 987_654_321, 3, 2, "A", 12, 34, 56]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .AISInterrogationRequest(
          station1: 123_456_789,
          station1Request1: .init(number: 1, subsection: 1, replySlot: 12),
          station1Request2: .init(number: 2, subsection: nil, replySlot: 34),
          station2: 987_654_321,
          station2Request: .init(number: 3, subsection: 2, replySlot: 56),
          channel: .A
        )
    )
  }

  @Test("throws when a sub-section is present without its message number")
  func throwsWhenASubSectionIsPresentWithoutItsMessageNumber() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISInterrogationRequest,
      fields: [123_456_789, 1, 1, nil, 2, nil, nil, nil, "A", 12, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 3)
  }
}
