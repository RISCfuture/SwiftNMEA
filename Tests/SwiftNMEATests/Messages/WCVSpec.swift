import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class WCVSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.100 WCV") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric, talker: .waterLevelDetection, format: .waypointClosure,
          fields: [12.3, "N", "KSQL", "D"])
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .waypointClosure(let closure, let identifier, let mode) = payload else {
          fail("expected .waypointClosure, got \(payload)")
          return
        }

        expect(closure).to(equal(.init(value: 12.3, unit: .knots)))
        expect(identifier).to(equal("KSQL"))
        expect(mode).to(equal(.differential))
      }
    }
  }
}
