import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SPWSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.98 SPW") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .securityPassword,
          fields: ["EPV", "211000001", 2, "SESAME"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .securityPassword(protectedSentence, uniqueID, level, password) = payload
        else {
          fail("expected .securityPassword, got \(payload)")
          return
        }

        expect(protectedSentence).to(equal(.unknown("EPV")))
        expect(uniqueID).to(equal("211000001"))
        expect(level).to(equal(.administrator))
        expect(password).to(equal("SESAME"))
      }

      it("throws an error for a reserved password level") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedInstrumentation,
          format: .securityPassword,
          fields: ["EPV", "211000001", 5, "SESAME"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
