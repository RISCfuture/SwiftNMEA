import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class CBRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.19 CBR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .navaidMessageBroadcastRates,
          fields: [
            1_234_567_890, 0, 0,
            23, 12, 1500, nil,
            2,
            11, 2, -1, nil,
            "R"
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
          case .navaidMessageBroadcastRates(
            let MMSI,
            let message,
            let index,
            let channelA,
            let scheduleType,
            let channelB,
            let type
          ) = payload
        else {
          fail("expected .navaidMessageBroadcastRates, got \(payload)")
          return
        }

        expect(MMSI).to(equal(1_234_567_890))
        expect(message).to(equal(.chain))
        expect(index).to(equal(0))

        guard case .start(let start, let slot, let interval) = channelA else {
          fail("expected .start, got \(channelA)")
          return
        }
        expect(start.hour).to(equal(23))
        expect(start.minute).to(equal(12))
        expect(slot).to(equal(.set(1500)))
        expect(interval).to(equal(.noChange))

        expect(channelB).to(equal(.discontinue))

        expect(scheduleType).to(equal(.CSTDMA))
        expect(type).to(equal(.reply))
      }
    }
  }
}
