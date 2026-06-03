import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SM3Spec: AsyncSpec {
  override static func spec() {
    describe("8.3.94 SM3") {
      it("parses a circular-area SafetyNET message") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCircularArea,
          fields: [
            "A", 42, 10345, 304, 1, 2, 24, 0, 2024, 6, 2, 14, 30,
            "5600.00", "N", "03400.00", "W", "035"
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
          case let .safetyNETCircularArea(
            status,
            identification,
            oceanRegion,
            priority,
            serviceCode,
            presentationCode,
            receptionTime,
            centre,
            radius
          ) = payload
        else {
          fail("expected safetyNETCircularArea, got \(payload)")
          return
        }

        expect(status).to(equal(.complete))
        expect(identification.uniqueMessageNumber).to(equal(42))
        expect(identification.lesSequenceNumber).to(equal(10345))
        expect(identification.lesID).to(equal(304))
        expect(oceanRegion).to(equal(.atlanticEast))
        expect(priority).to(equal(.urgency))
        expect(serviceCode).to(equal(.warning))
        expect(presentationCode).to(equal(.internationalAlphabet5))

        let expectedTime = calendar.date(
          from: .init(timeZone: .gmt, year: 2024, month: 6, day: 2, hour: 14, minute: 30)
        )
        expect(receptionTime).to(equal(expectedTime))

        expect(centre?.latitude.converted(to: .degrees).value).to(beCloseTo(56, within: 0.001))
        expect(centre?.longitude.converted(to: .degrees).value).to(beCloseTo(-34, within: 0.001))
        expect(radius?.converted(to: .nauticalMiles).value).to(beCloseTo(35, within: 0.001))
      }

      it("parses null centre, radius, and LES fields when MSI is incomplete") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCircularArea,
          fields: [
            "V", 7, nil, nil, 8, 9, nil, 0, 2024, 6, 2, 14, 30,
            nil, nil, nil, nil, nil
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .safetyNETCircularArea(
            status,
            identification,
            _,
            _,
            serviceCode,
            _,
            _,
            centre,
            radius
          ) = payload
        else {
          fail("expected safetyNETCircularArea, got \(payload)")
          return
        }

        expect(status).to(equal(.incomplete))
        expect(identification.uniqueMessageNumber).to(equal(7))
        expect(identification.lesSequenceNumber).to(beNil())
        expect(identification.lesID).to(beNil())
        expect(serviceCode).to(beNil())
        expect(centre).to(beNil())
        expect(radius).to(beNil())
      }

      it("throws for a reserved ocean region code") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCircularArea,
          fields: [
            "A", 42, 10345, 304, 5, 2, 24, 0, 2024, 6, 2, 14, 30,
            "5600.00", "N", "03400.00", "W", "035"
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
