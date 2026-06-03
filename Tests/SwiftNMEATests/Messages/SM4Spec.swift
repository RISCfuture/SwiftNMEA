import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SM4Spec: AsyncSpec {
  override static func spec() {
    describe("8.3.95 SM4") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETRectangularArea,
          fields: [
            "A", 5213, "000798", "798", 0, 3, 4, "00", 2012, 4, 5, 14, 30,
            "6000.00", "N", "01000.00", "W", 30, 25
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
          case let .safetyNETRectangularArea(
            status,
            identification,
            oceanRegion,
            priority,
            serviceCode,
            presentationCode,
            receptionTime,
            southWestCorner,
            latitudeExtent,
            longitudeExtent
          ) = payload
        else {
          fail("expected .safetyNETRectangularArea, got \(payload)")
          return
        }

        expect(status).to(equal(.complete))
        expect(identification.uniqueMessageNumber).to(equal(5213))
        expect(identification.lesSequenceNumber).to(equal(798))
        expect(identification.lesID).to(equal(798))
        expect(oceanRegion).to(equal(.atlanticWest))
        expect(priority).to(equal(.distress))
        expect(serviceCode).to(equal(.navigationalWarning))
        expect(presentationCode).to(equal(.internationalAlphabet5))

        let components = DateComponents(
          timeZone: .gmt,
          year: 2012,
          month: 4,
          day: 5,
          hour: 14,
          minute: 30
        )
        expect(receptionTime).to(equal(calendar.date(from: components)))

        expect(southWestCorner?.latitude.converted(to: .degrees).value)
          .to(beCloseTo(60, within: 0.001))
        expect(southWestCorner?.longitude.converted(to: .degrees).value)
          .to(beCloseTo(-10, within: 0.001))
        expect(latitudeExtent).to(equal(.init(value: 30, unit: .degrees)))
        expect(longitudeExtent).to(equal(.init(value: 25, unit: .degrees)))
      }

      it("parses null service, position, and extent fields") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETRectangularArea,
          fields: [
            "V", 7, nil, nil, 9, 1, nil, "00", 2024, 12, 31, 0, 0,
            nil, nil, nil, nil, nil, nil
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
          case let .safetyNETRectangularArea(
            status,
            identification,
            oceanRegion,
            _,
            serviceCode,
            _,
            _,
            southWestCorner,
            latitudeExtent,
            longitudeExtent
          ) = payload
        else {
          fail("expected .safetyNETRectangularArea, got \(payload)")
          return
        }

        expect(status).to(equal(.incomplete))
        expect(identification.uniqueMessageNumber).to(equal(7))
        expect(identification.lesSequenceNumber).to(beNil())
        expect(identification.lesID).to(beNil())
        expect(oceanRegion).to(equal(.all))
        expect(serviceCode).to(beNil())
        expect(southWestCorner).to(beNil())
        expect(latitudeExtent).to(beNil())
        expect(longitudeExtent).to(beNil())
      }

      it("throws an error for an invalid service code") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETRectangularArea,
          fields: [
            "A", 5213, "000798", "798", 0, 3, 14, "00", 2012, 4, 5, 14, 30,
            "6000.00", "N", "01000.00", "W", 30, 25
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
