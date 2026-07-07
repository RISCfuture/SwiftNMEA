import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.19 CBR")
struct CBRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .navaidMessageBroadcastRates(
        MMSI,
        message,
        index,
        channelA,
        scheduleType,
        channelB,
        type
      ) = payload
    else {
      Issue.record("expected .navaidMessageBroadcastRates, got \(payload)")
      return
    }

    #expect(MMSI == 1_234_567_890)
    #expect(message == .chain)
    #expect(index == 0)

    guard case let .start(start, slot, interval) = channelA else {
      Issue.record("expected .start, got \(channelA)")
      return
    }
    #expect(start.hour == 23)
    #expect(start.minute == 12)
    #expect(slot == .set(1500))
    #expect(interval == .noChange)

    #expect(channelB == .discontinue)

    #expect(scheduleType == .CSTDMA)
    #expect(type == .reply)
  }
}
