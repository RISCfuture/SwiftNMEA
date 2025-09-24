import Nimble
import Quick

@testable import SwiftNMEA

final class ABKSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.3 ABK") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISBroadcastAcknowledgement,
          fields: [123_456_789, "A", "6.1", 3, 1]
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
            .AISBroadcastAcknowledgement(
              MMSI: 123_456_789,
              channel: .A,
              messageID: "6.1",
              sequence: 3,
              type: .noAck
            )
          )
        )
      }
    }
  }
}
