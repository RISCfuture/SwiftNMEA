import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.125 WNC")
struct WNCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .distanceWaypointToWaypoint,
      fields: [
        123.4, "N", 234.5, "K",
        "KOAK", "KSQL"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .distanceWaypointToWaypoint(distanceNM, distanceKM, to, from) =
        payload
    else {
      Issue.record("expected .distanceWaypointToWaypoint, got \(payload)")
      return
    }

    #expect(distanceNM == .init(value: 123.4, unit: .nauticalMiles))
    #expect(distanceKM == .init(value: 234.5, unit: .kilometers))
    #expect(to == "KOAK")
    #expect(from == "KSQL")
  }
}
