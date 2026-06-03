import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SLMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.91 SLM") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .steeringLocationMode,
          fields: [1, "O", "Bow thruster panel", "P", "DP Main"]
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
            .steeringLocationMode(
              systemStatus: .active,
              location: .others,
              locationDescription: "Bow thruster panel",
              mode: .dynamicPositioning,
              subMode: "DP Main"
            )
          )
        )
      }

      it("parses a sentence with unavailable optional values") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .steeringLocationMode,
          fields: [0, "B", nil, "M", nil]
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
            .steeringLocationMode(
              systemStatus: .passive,
              location: .bridge,
              locationDescription: nil,
              mode: .manual,
              subMode: nil
            )
          )
        )
      }

      it("throws an error for an unknown system status") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .steeringLocationMode,
          fields: [5, "B", nil, "M", nil]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }

      it("throws an error when location is Others but description is missing") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .steering,
          format: .steeringLocationMode,
          fields: [1, "O", nil, "P", nil]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
      }
    }
  }
}
