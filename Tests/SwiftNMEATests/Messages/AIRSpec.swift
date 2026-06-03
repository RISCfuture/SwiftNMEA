import Nimble
import Quick

@testable import SwiftNMEA

final class AIRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.10 AIR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISInterrogationRequest,
          fields: [123_456_789, 1, 1, 2, nil, 987_654_321, 3, 2, "A", 12, 34, 56]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(
          equal(
            .AISInterrogationRequest(
              station1: 123_456_789,
              station1Request1: .init(number: 1, subsection: 1, replySlot: 12),
              station1Request2: .init(number: 2, subsection: nil, replySlot: 34),
              station2: 987_654_321,
              station2Request: .init(number: 3, subsection: 2, replySlot: 56),
              channel: .A
            )
          )
        )
      }

      it("throws when a sub-section is present without its message number") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISInterrogationRequest,
          fields: [123_456_789, 1, 1, nil, 2, nil, nil, nil, "A", 12, nil, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
        expect(error.fieldNumber).to(equal(3))
      }
    }
  }
}
