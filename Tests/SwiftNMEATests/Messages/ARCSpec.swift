import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ARCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.17 ARC") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -12)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommandRefused,
          fields: [
            hmsFractionFormatter.string(from: time),
            "NMA", 2456789, 12, "A"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertCommandRefused(actualTime, alert, refusedCommand) = payload else {
          fail("expected .alertCommandRefused, got \(payload)")
          return
        }

        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(alert.manufacturerMnemonic).to(equal("NMA"))
        expect(alert.identifier).to(equal(2_456_789))
        expect(alert.instance).to(equal(12))
        expect(refusedCommand).to(equal(.acknowledge))
      }

      it("parses a sentence with null optional fields") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommandRefused,
          fields: [
            nil, nil, 245, nil, "S"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertCommandRefused(actualTime, alert, refusedCommand) = payload else {
          fail("expected .alertCommandRefused, got \(payload)")
          return
        }

        expect(actualTime).to(beNil())
        expect(alert.manufacturerMnemonic).to(beNil())
        expect(alert.identifier).to(equal(245))
        expect(alert.instance).to(beNil())
        expect(refusedCommand).to(equal(.temporarySilence))
      }

      it("throws an error for an invalid refused command") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommandRefused,
          fields: [
            nil, nil, 245, 1, "Z"
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
        guard let error = messages.compactMap({ $0 as? MessageError }).first else {
          fail("expected MessageError, got \(messages)")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
