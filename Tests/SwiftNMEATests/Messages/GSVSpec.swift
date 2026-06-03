import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GSVSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.48 GSV") {
      it("parses a sentence") {

        // MARK: Setup

        let parser = SwiftNMEA()
        let sentences = [
          createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSSatellitesInView,
            fields: [
              2, 1, 7,
              "01", 11, 21, 31,
              "02", 12, 22, 32,
              "03", 13, 23, 33,
              "04", 14, 24, 34,
              1
            ]
          ),
          createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSSatellitesInView,
            fields: [
              2, 2, 7,
              "05", 15, 25, 35,
              "06", 16, 26, 36,
              "07", 17, 27, 37,
              nil, nil, nil, nil,
              1
            ]
          ),
          createSentence(
            delimiter: .parametric,
            talker: .GLONASS,
            format: .GNSSSatellitesInView,
            fields: [
              1, 1, 4,
              "65", 15, 25, 35,
              "66", 16, 26, 36,
              "67", 17, 27, 37,
              "68", 18, 28, 38,
              2
            ]
          )
        ]
        let data = sentences.joined().data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(5))
        guard let payload1 = (messages[2] as? Message)?.payload else {
          fail("expected Message, got \(messages[2])")
          return
        }
        guard let payload2 = (messages[4] as? Message)?.payload else {
          fail("expected Message, got \(messages[4])")
          return
        }

        // MARK: Message 1 (GPS)

        guard case let .GNSSSatellitesInView(satellites, total) = payload1 else {
          fail("expected .GNSSSatellitesInView, got \(payload1)")
          return
        }
        expect(total).to(equal(7))
        expect(satellites).to(haveCount(total))
        for i in 1...total {
          expect(satellites[i - 1].id).to(equal(.GPS(i, signal: .L1_CA)))
          expect(satellites[i - 1].position.elevation).to(
            equal(.init(value: Double(10 + i), unit: .degrees))
          )
          expect(satellites[i - 1].position.azimuth).to(
            equal(.init(degrees: Double(20 + i), reference: .true))
          )
          expect(satellites[i - 1].SNR).to(equal(30 + i))
        }

        // MARK: Message 2 (GLONASS)

        guard case let .GNSSSatellitesInView(satellites, total) = payload2 else {
          fail("expected .GNSSSatellitesInView, got \(payload2)")
          return
        }
        expect(total).to(equal(4))
        expect(satellites).to(haveCount(total))
        for i in 1...total {
          expect(satellites[i - 1].id).to(equal(.GLONASS(64 + i, signal: .G1_P)))
          expect(satellites[i - 1].position.elevation).to(
            equal(.init(value: Double(i + 14), unit: .degrees))
          )
          expect(satellites[i - 1].position.azimuth).to(
            equal(.init(degrees: Double(i + 24), reference: .true))
          )
          expect(satellites[i - 1].SNR).to(equal(i + 34))
        }
      }

      it("derives the constellation from the talker and parses a hex signal ID") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .beidou,
          format: .GNSSSatellitesInView,
          fields: [
            1, 1, 1,
            "05", 15, 25, 35,
            "C"  // BDS Signal ID B2Q (hex)
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload,
          case let .GNSSSatellitesInView(satellites, _) = payload
        else {
          fail("expected .GNSSSatellitesInView, got \(messages[1])")
          return
        }
        expect(satellites).to(haveCount(1))
        let expectedID: GNSS.SatelliteID = .beidou(5, signal: .B2Q)
        expect(satellites[0].id).to(equal(expectedID))
      }

      it("throws an error for an out-of-range signal ID") {
        let parser = SwiftNMEA()
        // GPS signal IDs only range 0–8; hex "F" (15) is out of range.
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GPS,
          format: .GNSSSatellitesInView,
          fields: [
            1, 1, 1,
            "01", 11, 21, 31,
            "F"  // out-of-range GPS Signal ID (hex)
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
