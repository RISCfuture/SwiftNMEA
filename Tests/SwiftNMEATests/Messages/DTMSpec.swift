import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class DTMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.31 DTM") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            "999", "F",
            "13.2", "N",
            "22.8", "W",
            "-12.5",
            "W84", nil
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
          case let .datumReference(
            localDatum,
            latitudeOffset,
            longitudeOffset,
            altitudeOffset,
            referenceDatum
          ) = payload
        else {
          fail("expected .datumReference, got \(payload)")
          return
        }

        expect(localDatum).to(equal(.userDefined(subdivision: "F")))
        expect(latitudeOffset).to(equal(.init(value: 13.2, unit: .arcMinutes)))
        expect(longitudeOffset).to(equal(.init(value: -22.8, unit: .arcMinutes)))
        expect(altitudeOffset).to(equal(.init(value: -12.5, unit: .meters)))
        expect(referenceDatum).to(equal(.WGS84))
      }

      it("parses a BDCS reference datum (C00)") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            "C00", nil,
            nil, nil,
            nil, nil,
            nil,
            "C00", nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .datumReference(localDatum, _, _, _, referenceDatum) = payload else {
          fail("expected .datumReference, got \(payload)")
          return
        }
        expect(localDatum).to(equal(.BDCS))
        expect(referenceDatum).to(equal(.BDCS))
      }

      it("parses a sentence with an unknown (null) local datum") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            nil, nil,
            nil, nil,
            nil, nil,
            nil,
            "W84", nil
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
          case let .datumReference(localDatum, _, _, _, referenceDatum) = payload
        else {
          fail("expected .datumReference, got \(payload)")
          return
        }

        expect(localDatum).to(beNil())
        expect(referenceDatum).to(equal(.WGS84))
      }

      it("throws when a user-defined datum omits an offset") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            "999", "F",
            "13.2", "N",
            nil, "W",
            "-12.5",
            "W84", nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
        expect(error.fieldNumber).to(equal(4))
      }

      it("throws for an invalid latitude-offset hemisphere character") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            "999", "F",
            "13.2", "X",
            "22.8", "W",
            "-12.5",
            "W84", nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badCharacterValue))
        expect(error.fieldNumber).to(equal(3))
      }
    }
  }
}
