import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class RLMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.78 RLM") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -10)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .galileo,
          format: .returnLink,
          fields: [
            "ABCDEF012345678",
            hmsFractionFormatter.string(from: time),
            "2",
            "0123456789ABCDEF01234567"
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
          case let .returnLink(beacon, actualTime, messageCode, messageBody) = payload
        else {
          fail("expected .returnLink, got \(payload)")
          return
        }

        expect(beacon).to(equal("ABCDEF012345678"))
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(messageCode).to(equal(.command))
        expect(messageBody).to(equal(Data(hex: "0123456789ABCDEF01234567")!))
      }

      it("parses a sentence with no time of reception") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .galileo,
          format: .returnLink,
          fields: [
            "ABCDEF012345678",
            nil,
            "1",
            "ABCD"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .returnLink(beacon, actualTime, messageCode, messageBody) = payload
        else {
          fail("expected .returnLink, got \(payload)")
          return
        }

        expect(beacon).to(equal("ABCDEF012345678"))
        expect(actualTime).to(beNil())
        expect(messageCode).to(equal(.acknowledgement))
        expect(messageBody).to(equal(Data(hex: "ABCD")!))
      }

      it("throws an error for a beacon ID of the wrong length") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .galileo,
          format: .returnLink,
          fields: [
            "ABCDEF",
            nil,
            "1",
            "ABCD"
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badNumericValue))
      }
    }
  }
}
