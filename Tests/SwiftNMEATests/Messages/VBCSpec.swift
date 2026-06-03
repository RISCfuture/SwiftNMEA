import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VBCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.112 VBC") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dockingSpeedData,
          fields: [
            12.3, 1.1, -1.2, 0.5, "A",
            23.4, 2.1, -2.2, 1.5, "V"
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
          case let .dockingSpeedData(water, waterValid, ground, groundValid) = payload
        else {
          fail("expected .dockingSpeedData, got \(payload)")
          return
        }

        expect(water.longitudinal).to(equal(.init(value: 12.3, unit: .knots)))
        expect(water.bowTransverse).to(equal(.init(value: 1.1, unit: .knots)))
        expect(water.transverse).to(equal(.init(value: -1.2, unit: .knots)))
        expect(water.sternTransverse).to(equal(.init(value: 0.5, unit: .knots)))
        expect(waterValid).to(beTrue())
        expect(ground.longitudinal).to(equal(.init(value: 23.4, unit: .knots)))
        expect(ground.bowTransverse).to(equal(.init(value: 2.1, unit: .knots)))
        expect(ground.transverse).to(equal(.init(value: -2.2, unit: .knots)))
        expect(ground.sternTransverse).to(equal(.init(value: 1.5, unit: .knots)))
        expect(groundValid).to(beFalse())
      }

      it("throws an error when the water-speed status is a null field") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dockingSpeedData,
          fields: [
            12.3, 1.1, -1.2, 0.5, "",
            23.4, 2.1, -2.2, 1.5, "A"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
      }

      it("throws an error for a non-numeric speed") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .dockingSpeedData,
          fields: [
            "bogus", 1.1, -1.2, 0.5, "A",
            23.4, 2.1, -2.2, 1.5, "V"
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badNumericValue))
      }
    }
  }
}
