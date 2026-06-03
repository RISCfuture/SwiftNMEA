import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class DSCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.29 DSC") {
      it("parses the distress example from the spec") {
        let parser = SwiftNMEA()
        let sentence = "$CVDSC,12,3601234560,12,05,00,1474712519,0817,,,S,E,*51\r\n"
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .DSC(
            format,
            MMSI,
            area,
            category,
            message1_1,
            message1_2,
            message2,
            message3,
            distressMMSI,
            distressMMSINature,
            acknowledgement,
            expansion
          ) = payload
        else {
          fail("expected .DSC, got \(payload)")
          return
        }

        let nature = DSC.DistressNature(rawValue: message1_1!)
        let commType = DSC.DistressCommunicationDesired(rawValue: message1_2!)
        let position = DSC.distressCoordinates(from: message2!)
        let time = DSC.time(from: message3!)

        expect(format).to(equal(.distress))
        expect(MMSI).to(equal(360_123_456))
        expect(area).to(beNil())
        expect(category).to(equal(.distress))
        expect(nature).to(equal(.sinking))
        expect(commType).to(equal(.F3E_G3E_allModesTP))
        expect(position!.latitude.value).to(beCloseTo(47.7833333333, within: 0.01))
        expect(position!.longitude.value).to(beCloseTo(-125.3166666667, within: 0.01))
        expect(distressMMSI).to(beNil())
        expect(distressMMSINature).to(beNil())
        expect(acknowledgement).to(equal(.end))
        expect(expansion).to(beTrue())

        let components = Calendar.current.dateComponents(in: .gmt, from: time!)
        expect(components.hour).to(equal(8))
        expect(components.minute).to(equal(17))
      }

      it("parses the relay example from the spec") {
        let parser = SwiftNMEA()
        let sentence = "$CTDSC,16,0112345670,12,12,09,1474712219,1234,9991212120,00,S*19\r\n"
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let message = messages[1] as? Message else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .DSC(
            format,
            MMSI,
            area,
            category,
            message1_1,
            message1_2,
            message2,
            message3,
            distressMMSI,
            distressMMSINature,
            acknowledgement,
            expansion
          ) = message.payload
        else {
          fail("expected .DSC, got \(message)")
          return
        }

        expect(format).to(equal(.allShips))
        expect(MMSI).to(equal(011_234_567))
        expect(area).to(beNil())
        expect(category).to(equal(.distress))
        expect(message1_1).to(equal("12"))
        expect(message1_2).to(equal("09"))
        expect(message2).to(equal("1474712219"))
        expect(message3).to(equal("1234"))
        expect(distressMMSI).to(equal(999_121_212))
        expect(distressMMSINature).to(equal(.fire))
        expect(acknowledgement).to(equal(.end))
        expect(expansion).to(beFalse())
      }

      it("parses the safety call example from the spec") {
        let parser = SwiftNMEA()
        let sentence = "$CTDSC,16,0112345670,08,09,26,041250,,,,S*11\r\n"
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let message = messages[1] as? Message else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .DSC(
            format,
            MMSI,
            area,
            category,
            message1_1,
            message1_2,
            message2,
            message3,
            distressMMSI,
            distressMMSINature,
            acknowledgement,
            expansion
          ) = message.payload
        else {
          fail("expected .DSC, got \(message)")
          return
        }

        expect(format).to(equal(.allShips))
        expect(MMSI).to(equal(011_234_567))
        expect(area).to(beNil())
        expect(category).to(equal(.safety))
        expect(message1_1).to(equal("09"))
        expect(message1_2).to(equal("26"))
        expect(message2).to(equal("041250"))
        expect(message3).to(beNil())
        expect(distressMMSI).to(beNil())
        expect(distressMMSINature).to(beNil())
        expect(acknowledgement).to(equal(.end))
        expect(expansion).to(beFalse())
      }

      it("parses a geographic sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commDSC,
          format: .DSC,
          fields: [
            "02", 1_351_210_102, "00",
            12, 26, 41_252_165, 10_500_012_345,
            9_876_543_210, "05", "B", ""
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
          case let .DSC(
            format,
            MMSI,
            area,
            category,
            message1_1,
            message1_2,
            message2,
            message3,
            distressMMSI,
            distressMMSINature,
            acknowledgement,
            expansion
          ) = payload
        else {
          fail("expected .DSC, got \(payload)")
          return
        }

        let telecommand1 = DSC.Telecommand1(rawValue: message1_1!)
        let telecommand2 = DSC.Telecommand2(rawValue: message1_2!)
        let freq = DSC.FrequencyChannel(rawValue: message2!)
        let phone = DSC.networkNumber(from: message3!)

        expect(format).to(equal(.geographic))
        expect(MMSI).to(beNil())
        expect(area).to(
          equal(
            .init(
              latitude: .init(value: 35, unit: .degrees),
              longitude: .init(value: -121, unit: .degrees),
              deltaLat: .init(value: 1, unit: .degrees),
              deltaLon: .init(value: 2, unit: .degrees)
            )
          )
        )
        expect(category).to(equal(.routine))
        expect(telecommand1).to(equal(.distressRelay))
        expect(telecommand2).to(equal(.noInformation))
        expect(freq).to(equal(.frequency(.init(value: 12_521_650, unit: .hertz))))
        expect(phone).to(equal("0012345"))
        expect(distressMMSI).to(equal(987_654_321))
        expect(distressMMSINature).to(equal(.sinking))
        expect(acknowledgement).to(equal(.acknowledgement))
        expect(expansion).to(beFalse())
      }

      it("decodes the ITU-R M.493-16 Table A1-3 first telecommands") {
        expect(DSC.Telecommand1(rawValue: "00")).to(equal(.telephonyAllModes))
        expect(DSC.Telecommand1(rawValue: "01")).to(equal(.telephonyDuplex))
        expect(DSC.Telecommand1(rawValue: "09")).to(equal(.telephonyJ3E))
        expect(DSC.Telecommand1(rawValue: "13")).to(equal(.teletypeFEC))
        expect(DSC.Telecommand1(rawValue: "15")).to(equal(.teletypeARQ))
      }
    }

    describe("DSC.FrequencyChannel (ITU-R M.493-16 Table A1-5)") {
      func hertz(_ value: Double) -> Measurement<UnitFrequency> {
        .init(value: value, unit: .hertz)
      }

      it("round-trips a multiple-of-100-Hz MF/HF frequency (six-digit form)") {
        // 2 187 500 Hz (MF DSC distress frequency) = 21875 × 100 Hz.
        let value = DSC.FrequencyChannel.frequency(hertz(2_187_500))
        expect(value.rawValue).to(equal("021875"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue)).to(equal(value))
        expect(DSC.FrequencyChannel(rawValue: "021875")).to(equal(value))
      }

      it("round-trips a seven-digit (10 Hz resolution) frequency") {
        // From the Table A1-5 worked usage: 41252165 = 1252165 × 10 = 12 521 650 Hz.
        let value = DSC.FrequencyChannel.frequency(hertz(12_521_650))
        expect(value.rawValue).to(equal("41252165"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue)).to(equal(value))
        expect(DSC.FrequencyChannel(rawValue: "41252165")).to(equal(value))
      }

      it("round-trips an HF/MF channel number") {
        let value = DSC.FrequencyChannel.channelHF_MF(1234)
        expect(value.rawValue).to(equal("301234"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue)).to(equal(value))
        expect(DSC.FrequencyChannel(rawValue: "301234")).to(equal(value))
      }

      it("round-trips an auto-VHF channel number") {
        let value = DSC.FrequencyChannel.autoVHF(2087)
        expect(value.rawValue).to(equal("802087"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue)).to(equal(value))
        expect(DSC.FrequencyChannel(rawValue: "802087")).to(equal(value))
      }

      it("round-trips a VHF working channel number") {
        // VHF channel 16 (distress/safety) coded as 90 + four-digit channel.
        let value = DSC.FrequencyChannel.channelVHF(16)
        expect(value.rawValue).to(equal("900016"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue)).to(equal(value))
        expect(DSC.FrequencyChannel(rawValue: "900016")).to(equal(value))
      }

      it("clamps an out-of-range frequency instead of crashing") {
        // ≥ 30 MHz is not representable; encoding clamps to the maximum 10 Hz form.
        let value = DSC.FrequencyChannel.frequency(hertz(30_000_000))
        expect(value.rawValue).to(equal("42999999"))
        expect(DSC.FrequencyChannel(rawValue: value.rawValue))
          .to(equal(.frequency(hertz(29_999_990))))
      }

      it("returns nil for malformed or out-of-range symbol strings") {
        expect(DSC.FrequencyChannel(rawValue: "")).to(beNil())
        expect(DSC.FrequencyChannel(rawValue: "12AB45")).to(beNil())
        // too short for the six-digit form
        expect(DSC.FrequencyChannel(rawValue: "0218")).to(beNil())
        // seven-digit form needs eight digits
        expect(DSC.FrequencyChannel(rawValue: "412345")).to(beNil())
        // VHF requires the TM digit to be 0
        expect(DSC.FrequencyChannel(rawValue: "910016")).to(beNil())
        // unused HM digit
        expect(DSC.FrequencyChannel(rawValue: "700000")).to(beNil())
      }
    }
  }
}
