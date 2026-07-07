import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.23 BWW")
struct BWWTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .bearingWaypointToWaypoint,
      fields: [12.3, "T", 13.3, "M", "KOAK", "KSQL"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .bearingWaypointToWaypoint(
          bearingTrue: .init(degrees: 12.3, reference: .true),
          bearingMagnetic: .init(degrees: 13.3, reference: .magnetic),
          toWaypointID: "KOAK",
          fromWaypointID: "KSQL"
        )
    )
  }
}
