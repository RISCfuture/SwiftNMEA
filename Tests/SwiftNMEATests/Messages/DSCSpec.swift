import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.29 DSC")
struct DSCTests {
  @Test("parses the distress example from the spec")
  func parsesTheDistressExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$CVDSC,12,3601234560,12,05,00,1474712519,0817,,,S,E,*51\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .DSC, got \(payload)")
      return
    }

    let nature = DSC.DistressNature(rawValue: message1_1!)
    let commType = DSC.DistressCommunicationDesired(rawValue: message1_2!)
    let position = DSC.distressCoordinates(from: message2!)
    let time = DSC.time(from: message3!)

    #expect(format == .distress)
    #expect(MMSI == 360_123_456)
    #expect(area == nil)
    #expect(category == .distress)
    #expect(nature == .sinking)
    #expect(commType == .F3E_G3E_allModesTP)
    #expect(abs(position!.latitude.value - 47.7833333333) < 0.01)
    #expect(abs(position!.longitude.value - (-125.3166666667)) < 0.01)
    #expect(distressMMSI == nil)
    #expect(distressMMSINature == nil)
    #expect(acknowledgement == .end)
    #expect(expansion)

    let components = Calendar.current.dateComponents(in: .gmt, from: time!)
    #expect(components.hour == 8)
    #expect(components.minute == 17)
  }

  @Test("parses the relay example from the spec")
  func parsesTheRelayExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$CTDSC,16,0112345670,12,12,09,1474712219,1234,9991212120,00,S*19\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
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
      Issue.record("expected .DSC, got \(message)")
      return
    }

    #expect(format == .allShips)
    #expect(MMSI == 011_234_567)
    #expect(area == nil)
    #expect(category == .distress)
    #expect(message1_1 == "12")
    #expect(message1_2 == "09")
    #expect(message2 == "1474712219")
    #expect(message3 == "1234")
    #expect(distressMMSI == 999_121_212)
    #expect(distressMMSINature == .fire)
    #expect(acknowledgement == .end)
    #expect(!expansion)
  }

  @Test("parses the safety call example from the spec")
  func parsesTheSafetyCallExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$CTDSC,16,0112345670,08,09,26,041250,,,,S*11\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
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
      Issue.record("expected .DSC, got \(message)")
      return
    }

    #expect(format == .allShips)
    #expect(MMSI == 011_234_567)
    #expect(area == nil)
    #expect(category == .safety)
    #expect(message1_1 == "09")
    #expect(message1_2 == "26")
    #expect(message2 == "041250")
    #expect(message3 == nil)
    #expect(distressMMSI == nil)
    #expect(distressMMSINature == nil)
    #expect(acknowledgement == .end)
    #expect(!expansion)
  }

  @Test("parses a geographic sentence")
  func parsesAGeographicSentence() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .DSC, got \(payload)")
      return
    }

    let telecommand1 = DSC.Telecommand1(rawValue: message1_1!)
    let telecommand2 = DSC.Telecommand2(rawValue: message1_2!)
    let freq = DSC.FrequencyChannel(rawValue: message2!)
    let phone = DSC.networkNumber(from: message3!)

    #expect(format == .geographic)
    #expect(MMSI == nil)
    #expect(
      area
        == .init(
          latitude: .init(value: 35, unit: .degrees),
          longitude: .init(value: -121, unit: .degrees),
          deltaLat: .init(value: 1, unit: .degrees),
          deltaLon: .init(value: 2, unit: .degrees)
        )
    )
    #expect(category == .routine)
    #expect(telecommand1 == .distressRelay)
    #expect(telecommand2 == .noInformation)
    #expect(freq == .frequency(.init(value: 12_521_650, unit: .hertz)))
    #expect(phone == "0012345")
    #expect(distressMMSI == 987_654_321)
    #expect(distressMMSINature == .sinking)
    #expect(acknowledgement == .acknowledgement)
    #expect(!expansion)
  }

  @Test("decodes the ITU-R M.493-16 Table A1-3 first telecommands")
  func decodesTheITURM49316TableA13FirstTelecommands() throws {
    #expect(DSC.Telecommand1(rawValue: "00") == .telephonyAllModes)
    #expect(DSC.Telecommand1(rawValue: "01") == .telephonyDuplex)
    #expect(DSC.Telecommand1(rawValue: "09") == .telephonyJ3E)
    #expect(DSC.Telecommand1(rawValue: "13") == .teletypeFEC)
    #expect(DSC.Telecommand1(rawValue: "15") == .teletypeARQ)
  }

  // MARK: - DSC.FrequencyChannel (ITU-R M.493-16 Table A1-5)

  private func hertz(_ value: Double) -> Measurement<UnitFrequency> {
    .init(value: value, unit: .hertz)
  }

  @Test("round-trips a multiple-of-100-Hz MF/HF frequency (six-digit form)")
  func roundTripsAMultipleOf100HzMFHFFrequencySixDigitForm() throws {
    // 2 187 500 Hz (MF DSC distress frequency) = 21875 × 100 Hz.
    let value = DSC.FrequencyChannel.frequency(hertz(2_187_500))
    #expect(value.rawValue == "021875")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == value)
    #expect(DSC.FrequencyChannel(rawValue: "021875") == value)
  }

  @Test("round-trips a seven-digit (10 Hz resolution) frequency")
  func roundTripsASevenDigit10HzResolutionFrequency() throws {
    // From the Table A1-5 worked usage: 41252165 = 1252165 × 10 = 12 521 650 Hz.
    let value = DSC.FrequencyChannel.frequency(hertz(12_521_650))
    #expect(value.rawValue == "41252165")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == value)
    #expect(DSC.FrequencyChannel(rawValue: "41252165") == value)
  }

  @Test("round-trips an HF/MF channel number")
  func roundTripsAnHFMFChannelNumber() throws {
    let value = DSC.FrequencyChannel.channelHF_MF(1234)
    #expect(value.rawValue == "301234")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == value)
    #expect(DSC.FrequencyChannel(rawValue: "301234") == value)
  }

  @Test("round-trips an auto-VHF channel number")
  func roundTripsAnAutoVHFChannelNumber() throws {
    let value = DSC.FrequencyChannel.autoVHF(2087)
    #expect(value.rawValue == "802087")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == value)
    #expect(DSC.FrequencyChannel(rawValue: "802087") == value)
  }

  @Test("round-trips a VHF working channel number")
  func roundTripsAVHFWorkingChannelNumber() throws {
    // VHF channel 16 (distress/safety) coded as 90 + four-digit channel.
    let value = DSC.FrequencyChannel.channelVHF(16)
    #expect(value.rawValue == "900016")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == value)
    #expect(DSC.FrequencyChannel(rawValue: "900016") == value)
  }

  @Test("clamps an out-of-range frequency instead of crashing")
  func clampsAnOutOfRangeFrequencyInsteadOfCrashing() throws {
    // ≥ 30 MHz is not representable; encoding clamps to the maximum 10 Hz form.
    let value = DSC.FrequencyChannel.frequency(hertz(30_000_000))
    #expect(value.rawValue == "42999999")
    #expect(DSC.FrequencyChannel(rawValue: value.rawValue) == .frequency(hertz(29_999_990)))
  }

  @Test("returns nil for malformed or out-of-range symbol strings")
  func returnsNilForMalformedOrOutOfRangeSymbolStrings() throws {
    #expect(DSC.FrequencyChannel(rawValue: "") == nil)
    #expect(DSC.FrequencyChannel(rawValue: "12AB45") == nil)
    // too short for the six-digit form
    #expect(DSC.FrequencyChannel(rawValue: "0218") == nil)
    // seven-digit form needs eight digits
    #expect(DSC.FrequencyChannel(rawValue: "412345") == nil)
    // VHF requires the TM digit to be 0
    #expect(DSC.FrequencyChannel(rawValue: "910016") == nil)
    // unused HM digit
    #expect(DSC.FrequencyChannel(rawValue: "700000") == nil)
  }
}
