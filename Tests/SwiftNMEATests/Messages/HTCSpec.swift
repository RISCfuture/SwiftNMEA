import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.58 HTC")
struct HTCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .autopilotGeneral,
      format: .headingControlCommand,
      fields: [
        "A", 5.5, "L",
        "R", "T",
        6.5, 2.0, 0.5, 1.5,
        180.1, 0.25, 190.5, "M",
        "R"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .headingControlCommand(
        heading,
        track,
        rudderAngle,
        override,
        mode,
        turnMode,
        rudderLimit,
        headingLimit,
        trackLimit,
        radius,
        rate,
        status
      ) =
        payload
    else {
      Issue.record("expected .headingControlCommand, got \(payload)")
      return
    }

    #expect(heading!.angle == .init(value: 180.1, unit: .degrees))
    #expect(heading!.reference == .magnetic)
    #expect(track!.angle == .init(value: 190.5, unit: .degrees))
    #expect(track!.reference == .magnetic)
    #expect(rudderAngle == .init(value: -5.5, unit: .degrees))
    #expect(override)
    #expect(mode == .rudderControl)
    #expect(turnMode == .rate)
    #expect(rudderLimit == .init(value: 6.5, unit: .degrees))
    #expect(headingLimit == .init(value: 2.0, unit: .degrees))
    #expect(trackLimit == .init(value: 0.25, unit: .nauticalMiles))
    #expect(radius == .init(value: 0.5, unit: .nauticalMiles))
    #expect(rate == .init(value: 1.5, unit: .degreesPerMinute))
    #expect(status == .reply)
  }
}
