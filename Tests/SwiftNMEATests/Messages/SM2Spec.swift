import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SM2Spec: AsyncSpec {
  override static func spec() {
    describe("8.3.93 SM2") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCoastalWarningArea,
          fields: [
            "A", 42, 10345, 104, 1, 1, 13, 0,
            2024, 6, 27, 13, 56,
            5, "C", "A"
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
          case let .safetyNETCoastalWarningArea(
            status,
            identification,
            oceanRegion,
            priority,
            serviceCode,
            presentationCode,
            receptionTime,
            warningArea,
            warningAreaLetter,
            subjectIndicator
          ) = payload
        else {
          fail("expected .safetyNETCoastalWarningArea, got \(payload)")
          return
        }

        expect(status).to(equal(.complete))
        expect(identification.uniqueMessageNumber).to(equal(42))
        expect(identification.lesSequenceNumber).to(equal(10345))
        expect(identification.lesID).to(equal(104))
        expect(oceanRegion).to(equal(.atlanticEast))
        expect(priority).to(equal(.safety))
        expect(serviceCode).to(equal(.coastalWarning))
        expect(presentationCode).to(equal(.internationalAlphabet5))
        let components = DateComponents(
          timeZone: .gmt,
          year: 2024,
          month: 6,
          day: 27,
          hour: 13,
          minute: 56,
          second: 0
        )
        expect(receptionTime).to(equal(calendar.date(from: components)))
        expect(warningArea).to(equal(5))
        expect(warningAreaLetter).to(equal("C"))
        expect(subjectIndicator).to(equal(.navigationalWarnings))
      }

      it("parses a sentence with unavailable values") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCoastalWarningArea,
          fields: [
            "V", 42, nil, nil, 8, 9, nil, 0,
            2024, 6, 27, 13, 56,
            nil, nil, nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .safetyNETCoastalWarningArea(
            status,
            identification,
            _,
            _,
            serviceCode,
            _,
            _,
            warningArea,
            warningAreaLetter,
            subjectIndicator
          ) = payload
        else {
          fail("expected .safetyNETCoastalWarningArea, got \(payload)")
          return
        }

        expect(status).to(equal(.incomplete))
        expect(identification.lesSequenceNumber).to(beNil())
        expect(identification.lesID).to(beNil())
        expect(serviceCode).to(beNil())
        expect(warningArea).to(beNil())
        expect(warningAreaLetter).to(beNil())
        expect(subjectIndicator).to(beNil())
      }

      it("throws an error for an out-of-range NAVAREA number") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCoastalWarningArea,
          fields: [
            "A", 42, 10345, 104, 1, 1, 13, 0,
            2024, 6, 27, 13, 56,
            22, "C", "A"
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badValue))
      }

      it("throws an error for an out-of-range reception date") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commSatellite,
          format: .safetyNETCoastalWarningArea,
          fields: [
            "A", 42, 10345, 104, 1, 1, 13, 0,
            2024, 13, 27, 13, 56,
            5, "C", "A"
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badDate))
      }
    }
  }
}
