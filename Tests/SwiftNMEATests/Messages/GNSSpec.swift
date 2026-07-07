import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.44 GNS")
struct GNSTests {
  @Test("parses the first example from the spec")
  func parsesTheFirstExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(
      to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,DA,14,0.9,1005.543,6.5,5.2,23,S"
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
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
      Issue.record("expected .GNSSFix, got \(message)")
      return
    }

    #expect(abs(position!.latitude.value - 37.3737611833) < 0.000001)
    #expect(abs(position!.longitude.value - -122.9809369167) < 0.000001)
    #expect(position!.altitude == .init(value: 1005.543, unit: .meters))
    #expect(
      mode == [
        .GPS: .differential,
        .GLONASS: .autonomous
      ]
    )
    #expect(numSatellites == 14)
    #expect(HDOP == 0.9)
    #expect(geoidalSeparation == .init(value: 6.5, unit: .meters))
    #expect(DGPSAge == .init(value: 5.2, unit: .seconds))
    #expect(DGPSReferenceStationID == 23)
    #expect(status == .safe)

    let components = Calendar.current.dateComponents(in: .gmt, from: time)
    #expect(components.hour == 12)
    #expect(components.minute == 23)
    #expect(components.second == 10)
    #expect(abs(Double(components.nanosecond!) - 200_000_000) < 100_000)
  }

  @Test("parses the second example from the spec")
  func parsesTheSecondExampleFromTheSpec()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$GPGNS,122310.2,,,,,,7,,,,5.2,23,S")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
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
      Issue.record("expected .GNSSFix, got \(message)")
      return
    }

    #expect(position == nil)
    #expect(mode == nil)
    #expect(numSatellites == 7)
    #expect(HDOP == nil)
    #expect(geoidalSeparation == nil)
    #expect(DGPSAge == .init(value: 5.2, unit: .seconds))
    #expect(DGPSReferenceStationID == 23)
    #expect(status == .safe)

    let components = Calendar.current.dateComponents(in: .gmt, from: time)
    #expect(components.hour == 12)
    #expect(components.minute == 23)
    #expect(components.second == 10)
    #expect(abs(Double(components.nanosecond!) - 200_000_000) < 100_000)
  }

  @Test("parses a six-system mode indicator (ed.6.0)")
  func parsesASixSystemModeIndicator() async throws {
    let parser = SwiftNMEA()
    // The six-system mode indicator field is short enough to keep the
    // sentence within the 82-character limit when other fields are trimmed.
    let sentence = applyChecksum(
      to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,ADEPSR,14,0.9,1005.5,,,,S"
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let message = messages[1] as? Message,
      case let .GNSSFix(_, _, mode, _, _, _, _, _, _) = message.payload
    else {
      Issue.record("expected .GNSSFix, got \(messages[1])")
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
    #expect(mode == expectedMode)
  }

  @Test("rejects an over-length sentence (ed.6.0)")
  func rejectsAnOverLengthSentence() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(
      to: "$GNGNS,122310.2,3722.425671,N,12258.856215,W,ADEPSR,14,0.9,1005.543,6.5,5.2,23,S"
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 1)
    guard let error = messages[0] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[0])")
      return
    }
    #expect(error.type == .sentenceTooLong)
  }
}
