import Nimble
import Quick
@testable import SwiftNMEA

final class ACKSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.6 ACK") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .navWatchAlarm, format: .alarmAcknowledgement,
                        fields: [123]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                expect(payload).to(equal(
                    .alarmAcknowledgement(identifier: 123)
                ))
            }
        }
    }
}
