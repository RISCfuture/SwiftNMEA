import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class ETLSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.28 ETL") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -12),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .engineRoomMonitor, format: .engineTelegraph,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "O", "04", "30", "B", 0]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .engineTelegraph(actualTime, type, position, subPosition, location, number) = payload else {
                    fail("expected .engineTelegraph, got \(payload)")
                    return
                }

                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(type).to(equal(.order))
                expect(position).to(equal(.aheadFull))
                expect(subPosition).to(equal(.fullAway))
                expect(location).to(equal(.bridge))
                expect(number).to(equal(0))
            }
        }
    }
}
