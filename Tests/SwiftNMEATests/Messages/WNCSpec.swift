import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class WNCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.101 WNC") {
      it("parses a sentence") {
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

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .distanceWaypointToWaypoint(let distanceNM, let distanceKM, let to, let from) =
            payload
        else {
          fail("expected .distanceWaypointToWaypoint, got \(payload)")
          return
        }

        expect(distanceNM).to(equal(.init(value: 123.4, unit: .nauticalMiles)))
        expect(distanceKM).to(equal(.init(value: 234.5, unit: .kilometers)))
        expect(to).to(equal("KOAK"))
        expect(from).to(equal("KSQL"))
      }
    }
  }
}
