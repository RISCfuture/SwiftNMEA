import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ACSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.7 ACS") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -120)
        let components = calendar.dateComponents([.year, .month, .day], from: time)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISChannelInformationSource,
          fields: [
            1,
            123_456_789,
            hmsFractionFormatter.string(from: time),
            components.year,
            components.month,
            components.day
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .AISChannelInformationSource(let sequenceNumber, let MMSI, let actualTime) = payload
        else {
          fail("expected .AIChannelInformationSource, got \(payload)")
          return
        }
        expect(sequenceNumber).to(equal(1))
        expect(MMSI).to(equal(123_456_789))
        expect(actualTime).to(beCloseTo(time, within: 0.01))
      }
    }
  }
}
