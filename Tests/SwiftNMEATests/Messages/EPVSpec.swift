import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class EPVSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.33 EPV") {
      it("parses a command sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .ECDIS,
          format: .equipmentProperty,
          fields: ["C", "AI", "503123450", 101, "38400"]
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
            .equipmentProperty(
              type: .command,
              reference: .init(type: .automaticID, uniqueID: "503123450"),
              property: .init(rawValue: 101),
              value: "38400"
            )
          )
        )
      }

      it("parses a report sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .automaticID,
          format: .equipmentProperty,
          fields: ["R", "AI", "503123450", 101, "38400"]
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
            .equipmentProperty(
              type: .reply,
              reference: .init(type: .automaticID, uniqueID: "503123450"),
              property: .init(rawValue: 101),
              value: "38400"
            )
          )
        )
      }

      it("throws when the property identifier is negative") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .ECDIS,
          format: .equipmentProperty,
          fields: ["C", "AI", "503123450", -1, "38400"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badNumericValue))
      }
    }
  }
}
