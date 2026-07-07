import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.103 TLL")
struct TLLTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .targetPosition,
      fields: [
        12,
        "3730.00", "N", "12115.00", "W",
        "TGT1",
        hmsFractionFormatter.string(from: time),
        "Q", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .targetPosition(
        number,
        position,
        name,
        actualTime,
        status,
        isReference
      ) =
        payload
    else {
      Issue.record("expected .targetPosition, got \(payload)")
      return
    }

    #expect(number == 12)
    #expect(position.latitude == .init(value: 37.5, unit: .degrees))
    #expect(position.longitude == .init(value: -121.25, unit: .degrees))
    #expect(name == "TGT1")
    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(status == .query)
    #expect(!isReference)
  }
}
