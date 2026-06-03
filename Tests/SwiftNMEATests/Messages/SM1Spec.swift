import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SM1Spec: AsyncSpec {
  override static func spec() {
    describe("8.3.92 SM1") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETAllShips,
          fields: ["A", 1234, "010345", "104", 1, 2, 31, "00", 2024, 6, 2, 13, 56, 5]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .safetyNETAllShips(
            status,
            identification,
            oceanRegion,
            priority,
            serviceCode,
            presentationCode,
            receptionTime,
            addressCode
          ) = payload
        else {
          fail("expected .safetyNETAllShips, got \(payload)")
          return
        }

        expect(status).to(equal(.complete))
        expect(identification.uniqueMessageNumber).to(equal(1234))
        expect(identification.lesSequenceNumber).to(equal(10345))
        expect(identification.lesID).to(equal(104))
        expect(oceanRegion).to(equal(.atlanticEast))
        expect(priority).to(equal(.urgency))
        expect(serviceCode).to(equal(.navAreaWarning))
        expect(presentationCode).to(equal(.internationalAlphabet5))
        let components = DateComponents(
          timeZone: .gmt,
          year: 2024,
          month: 6,
          day: 2,
          hour: 13,
          minute: 56
        )
        expect(receptionTime).to(equal(calendar.date(from: components)))
        expect(addressCode).to(equal(5))
      }

      it("parses null sequence, LES ID, service, and address fields") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETAllShips,
          fields: ["V", 7, nil, nil, 9, 1, nil, "00", 2024, 12, 31, 0, 0, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .safetyNETAllShips(
            status,
            identification,
            oceanRegion,
            _,
            serviceCode,
            _,
            _,
            addressCode
          ) = payload
        else {
          fail("expected .safetyNETAllShips, got \(payload)")
          return
        }

        expect(status).to(equal(.incomplete))
        expect(identification.uniqueMessageNumber).to(equal(7))
        expect(identification.lesSequenceNumber).to(beNil())
        expect(identification.lesID).to(beNil())
        expect(oceanRegion).to(equal(.all))
        expect(serviceCode).to(beNil())
        expect(addressCode).to(beNil())
      }

      it("throws an error for a reserved ocean region code") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETAllShips,
          fields: ["A", 1234, "010345", "104", 4, 1, 31, "00", 2024, 6, 2, 13, 56, 5]
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
