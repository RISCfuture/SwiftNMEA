import Nimble
import Quick
@testable import SwiftNMEA

final class AIRSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.8 AIR") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISInterrogationRequest,
                        fields: [123456789, "1.1", "2", 987654321, "3.2", "A", 12, 34, 56]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                expect(payload).to(equal(
                    .AISInterrogationRequest(station1: 123456789,
                                             station1Request1: .init(number: 1, subsection: 1, replySlot: 12),
                                             station1Request2: .init(number: 2, subsection: nil, replySlot: 34),
                                             station2: 987654321,
                                             station2Request: .init(number: 3, subsection: 2, replySlot: 56),
                                             channel: .A)
                ))
            }
        }
    }
}
