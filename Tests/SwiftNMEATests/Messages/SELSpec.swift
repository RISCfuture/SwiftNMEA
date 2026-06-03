import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SELSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.89 SEL") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dataSelection,
          fields: ["POS", "GP0001", "HEA", "HE0001"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(equal(.dataSelection([.position: "GP0001", .heading: "HE0001"])))
      }

      it("parses a null source SFI") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dataSelection,
          fields: ["SOG", "", "TIM", "TI0001"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(equal(.dataSelection([.speedCourseOverGround: nil, .time: "TI0001"])))
      }

      it("throws an error for an unknown data id") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dataSelection,
          fields: ["XXX", "GP0001"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
        expect(error.fieldNumber).to(equal(0))
      }

      it("throws an error for a duplicate data id") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dataSelection,
          fields: ["POS", "GP0001", "POS", "GP0002"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badValue))
        expect(error.fieldNumber).to(equal(2))
      }
    }
  }
}
