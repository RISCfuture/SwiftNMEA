import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class XDRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.102 WPL") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .waterLevelDetection,
          format: .waypointLocation,
          fields: ["3530.00", "N", "12215.00", "W", "KOAK"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .waypointLocation(let location, let identifier) = payload else {
          fail("expected .waypointLocation, got \(payload)")
          return
        }

        expect(location.latitude).to(equal(.init(value: 35.5, unit: .degrees)))
        expect(location.longitude).to(equal(.init(value: -122.25, unit: .degrees)))
        expect(identifier).to(equal("KOAK"))
      }
    }
  }
}
