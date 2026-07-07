import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.77 PRC")
struct PRCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .propulsion,
      format: .propulsionRemoteControl,
      fields: [
        50.0, "A",
        2250.0, "R",
        13.0, "D",
        "B", 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .propulsionRemoteControl(
        leverDemandPosition,
        leverDemandValid,
        RPMDemand,
        pitchDemand,
        location,
        engineNumber
      ) = payload
    else {
      Issue.record("expected .propulsionRemoteControl, got \(payload)")
      return
    }

    #expect(leverDemandPosition == 50)
    #expect(leverDemandValid)
    #expect(RPMDemand == .value(.init(value: 2250, unit: .revolutionsPerMinute)))
    #expect(pitchDemand == .value(.init(value: 13, unit: .degrees)))
    #expect(location == .bridge)
    #expect(engineNumber == 0)
  }
}
