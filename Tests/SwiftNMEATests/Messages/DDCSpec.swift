import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class DDCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.26 DDC") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .depthSounder,
          format: .displayDimmingControl,
          fields: ["K", 50, "D", "R", "O"]
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
            .displayDimmingControl(
              preset: .dusk,
              brightness: 50,
              colorPalette: .day,
              status: .reply,
              commandMode: .operational
            )
          )
        )
      }

      it("throws when the command mode is missing") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .depthSounder,
          format: .displayDimmingControl,
          fields: ["K", 50, "D", "R", nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
      }
    }
  }
}
