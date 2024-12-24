import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class ACSSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.7 ACS") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -120),
                    components = calendar.dateComponents([.year, .month, .day], from: time),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commVHF, format: .AISChannelInformationSource,
                        fields: [1,
                                 123456789,
                                 hmsFractionFormatter.string(from: time),
                                 components.year,
                                 components.month,
                                 components.day]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .AISChannelInformationSource(sequenceNumber, MMSI, actualTime) = payload else {
                    fail("expected .AIChannelInformationSource, got \(payload)")
                    return
                }
                expect(sequenceNumber).to(equal(1))
                expect(MMSI).to(equal(123456789))
                expect(actualTime).to(beCloseTo(time, within: 0.01))
            }
        }
    }
}
