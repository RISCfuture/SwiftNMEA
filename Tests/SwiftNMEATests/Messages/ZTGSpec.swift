import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.133 ZTG` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -1)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .timeToDestination,
      fields: [hmsFractionFormatter.string(from: time), "010203.04", "KOAK"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .timeToDestination(observation, timeToGo, destinationID) = payload else {
      Issue.record("expected .timeToDestination, got \(payload)")
      return
    }

    #expect(abs(observation.timeIntervalSince(time)) < 0.01)
    #expect(timeToGo == .seconds(3723) + .milliseconds(40))
    #expect(destinationID == "KOAK")
  }
}
