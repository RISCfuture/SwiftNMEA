import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.8 ACS")
struct ACSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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
        components.day,
        components.month,
        components.year
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .AISChannelInformationSource(sequenceNumber, MMSI, actualTime) = payload
    else {
      Issue.record("expected .AIChannelInformationSource, got \(payload)")
      return
    }
    #expect(sequenceNumber == 1)
    #expect(MMSI == 123_456_789)
    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
  }
}
