import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class BODSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.15 BOD") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .bearingOriginToDest,
          fields: [12.3, "T", 13.3, "M", "KOAK", "KSQL"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(
          equal(
            .bearingOriginToDest(
              bearingTrue: .init(degrees: 12.3, reference: .true),
              bearingMagnetic: .init(degrees: 13.3, reference: .magnetic),
              destinationWaypointID: "KOAK",
              originWaypointID: "KSQL"
            )
          )
        )
      }
    }
  }
}
