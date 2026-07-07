import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.104 TRC")
struct TRCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .propulsion,
      format: .thrusterControl,
      fields: [1, 12.3, "P", 23.4, "D", 123.4, "B", "R"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .thrusterControl(
        number,
        RPMDemand,
        pitchDemand,
        azimuthDemand,
        location,
        status
      ) =
        payload
    else {
      Issue.record("expected .thrusterControl, got \(payload)")
      return
    }

    #expect(number == 1)
    #expect(RPMDemand == .percent(12.3))
    #expect(pitchDemand == .value(.init(value: 23.4, unit: .degrees)))
    #expect(azimuthDemand == .init(value: 123.4, unit: .degrees))
    #expect(location == .bridge)
    #expect(status == .reply)
  }
}
