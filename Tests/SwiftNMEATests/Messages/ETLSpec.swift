import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.34 ETL")
struct ETLTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -12)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .engineRoomMonitor,
      format: .engineTelegraph,
      fields: [
        hmsFractionFormatter.string(from: time),
        "O", "04", "30", "B", 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .engineTelegraph(
        actualTime,
        type,
        position,
        subPosition,
        location,
        number
      ) =
        payload
    else {
      Issue.record("expected .engineTelegraph, got \(payload)")
      return
    }

    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(type == .order)
    #expect(position == .aheadFull)
    #expect(subPosition == .fullAway)
    #expect(location == .bridge)
    #expect(number == 0)
  }
}
