import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ACNSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.7 ACN") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -2000)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommand,
          fields: [
            hmsFractionFormatter.string(from: time),
            "ABC", 2456789, 42, "C", "A"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertCommand(actualTime, alert, command) = payload else {
          fail("expected .alertCommand, got \(payload)")
          return
        }
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(alert).to(
          equal(.init(manufacturerMnemonic: "ABC", identifier: 2_456_789, instance: 42))
        )
        expect(command).to(equal(.acknowledge))
      }

      it("parses a sentence with null optional fields") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommand,
          fields: [nil, nil, 1, nil, "C", "Q"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertCommand(actualTime, alert, command) = payload else {
          fail("expected .alertCommand, got \(payload)")
          return
        }
        expect(actualTime).to(beNil())
        expect(alert).to(equal(.init(manufacturerMnemonic: nil, identifier: 1, instance: nil)))
        expect(command).to(equal(.requestRepeat))
      }

      it("throws an error when the sentence status flag is not \"C\"") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommand,
          fields: [nil, nil, 1, 2, "R", "A"]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badValue))
      }

      it("throws an error for acknowledge of alert instance 0") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .alertCommand,
          fields: [nil, nil, 1, 0, "C", "A"]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badValue))
      }
    }
  }
}
