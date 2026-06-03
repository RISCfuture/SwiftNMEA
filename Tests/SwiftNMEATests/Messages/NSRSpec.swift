import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class NSRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.74 NSR") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .navigationStatusReport,
          fields: ["P", "A", "F", "V", "D", "A", "N", "N", "P", "A", "W", "P", "A"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .navigationStatusReport(
            headingIntegrity,
            headingPlausibility,
            positionIntegrity,
            positionPlausibility,
            STWIntegrity,
            STWPlausibility,
            SOGCOGIntegrity,
            SOGCOGPlausibility,
            depthIntegrity,
            depthPlausibility,
            STWMode,
            timeIntegrity,
            timePlausibility
          ) = payload
        else {
          fail("expected .navigationStatusReport, got \(payload)")
          return
        }

        expect(headingIntegrity).to(equal(.passed))
        expect(headingPlausibility).to(equal(.plausible))
        expect(positionIntegrity).to(equal(.failed))
        expect(positionPlausibility).to(equal(.notPlausible))
        expect(STWIntegrity).to(equal(.doubtful))
        expect(STWPlausibility).to(equal(.plausible))
        expect(SOGCOGIntegrity).to(equal(.unavailable))
        expect(SOGCOGPlausibility).to(equal(.unavailable))
        expect(depthIntegrity).to(equal(.passed))
        expect(depthPlausibility).to(equal(.plausible))
        expect(STWMode).to(equal(.measured))
        expect(timeIntegrity).to(equal(.passed))
        expect(timePlausibility).to(equal(.plausible))
      }

      it("throws an error for an invalid integrity value") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .navigationStatusReport,
          fields: ["X", "A", "P", "A", "P", "A", "P", "A", "P", "A", "W", "P", "A"]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
