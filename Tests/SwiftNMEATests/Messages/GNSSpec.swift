import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GNSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.44 GNS") {
      it("parses the first example from the spec") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(
          to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,DA,14,0.9,1005.543,6.5,5.2,23,S"
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let message = messages[1] as? Message else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .GNSSFix(
            position,
            time,
            mode,
            numSatellites,
            HDOP,
            geoidalSeparation,
            DGPSAge,
            DGPSReferenceStationID,
            status
          ) = message.payload
        else {
          fail("expected .GNSSFix, got \(message)")
          return
        }

        expect(position!.latitude.value).to(beCloseTo(37.3737611833, within: 0.000001))
        expect(position!.longitude.value).to(beCloseTo(-122.9809369167, within: 0.000001))
        expect(position!.altitude).to(equal(.init(value: 1005.543, unit: .meters)))
        expect(mode).to(
          equal([
            .GPS: .differential,
            .GLONASS: .autonomous
          ])
        )
        expect(numSatellites).to(equal(14))
        expect(HDOP).to(equal(0.9))
        expect(geoidalSeparation).to(equal(.init(value: 6.5, unit: .meters)))
        expect(DGPSAge).to(equal(.init(value: 5.2, unit: .seconds)))
        expect(DGPSReferenceStationID).to(equal(23))
        expect(status).to(equal(.safe))

        let components = Calendar.current.dateComponents(in: .gmt, from: time)
        expect(components.hour).to(equal(12))
        expect(components.minute).to(equal(23))
        expect(components.second).to(equal(10))
        expect(Double(components.nanosecond!)).to(beCloseTo(200_000_000, within: 100_000))
      }

      it("parses the second example from the spec") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(to: "$GPGNS,122310.2,,,,,,7,,,,5.2,23,S")
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let message = messages[1] as? Message else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .GNSSFix(
            position,
            time,
            mode,
            numSatellites,
            HDOP,
            geoidalSeparation,
            DGPSAge,
            DGPSReferenceStationID,
            status
          ) = message.payload
        else {
          fail("expected .GNSSFix, got \(message)")
          return
        }

        expect(position).to(beNil())
        expect(mode).to(beNil())
        expect(numSatellites).to(equal(7))
        expect(HDOP).to(beNil())
        expect(geoidalSeparation).to(beNil())
        expect(DGPSAge).to(equal(.init(value: 5.2, unit: .seconds)))
        expect(DGPSReferenceStationID).to(equal(23))
        expect(status).to(equal(.safe))

        let components = Calendar.current.dateComponents(in: .gmt, from: time)
        expect(components.hour).to(equal(12))
        expect(components.minute).to(equal(23))
        expect(components.second).to(equal(10))
        expect(Double(components.nanosecond!)).to(beCloseTo(200_000_000, within: 100_000))
      }

      it("parses a six-system mode indicator (ed.6.0)") {
        let parser = SwiftNMEA()
        // The six-system mode indicator field is short enough to keep the
        // sentence within the 82-character limit when other fields are trimmed.
        let sentence = applyChecksum(
          to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,ADEPSR,14,0.9,1005.5,,,,S"
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let message = messages[1] as? Message,
          case let .GNSSFix(_, _, mode, _, _, _, _, _, _) = message.payload
        else {
          fail("expected .GNSSFix, got \(messages[1])")
          return
        }
        let expectedMode: [GNSS.System: Navigation.Mode] = [
          .GPS: .autonomous,
          .GLONASS: .differential,
          .galileo: .estimated,
          .beidou: .precise,
          .QZSS: .simulator,
          .navIC: .RTK
        ]
        expect(mode).to(equal(expectedMode))
      }

      it("rejects an over-length sentence (ed.6.0)") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(
          to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,ADEPSR,14,0.9,1005.543,6.5,5.2,23,S"
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(1))
        guard let error = messages[0] as? MessageError else {
          fail("expected MessageError, got \(messages[0])")
          return
        }
        expect(error.type).to(equal(.sentenceTooLong))
      }
    }
  }
}
