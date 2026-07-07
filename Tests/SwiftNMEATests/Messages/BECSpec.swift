import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.19 BEC")
struct BECTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -1200)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .bearingDistanceToWaypointDR,
      fields: [
        hmsFractionFormatter.string(from: time),
        "3730.00", "N", "12145.00", "W",
        120.5, "T", 125.1, "M",
        123.4, "N",
        "KSQL"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .bearingDistanceToWaypointDR(
        observationTime,
        waypointPosition,
        bearingTrue,
        bearingMagnetic,
        distance,
        waypointID
      ) = payload
    else {
      Issue.record("expected .bearingDistanceToWaypointDR, got \(payload)")
      return
    }

    #expect(abs(observationTime.timeIntervalSince(time)) < 0.01)
    #expect(waypointPosition == .init(latitude: 37.5, longitude: -121.75))
    #expect(bearingTrue == .init(degrees: 120.5, reference: .true))
    #expect(bearingMagnetic == .init(degrees: 125.1, reference: .magnetic))
    #expect(distance == .init(value: 123.4, unit: .nauticalMiles))
    #expect(waypointID == "KSQL")
  }
}
