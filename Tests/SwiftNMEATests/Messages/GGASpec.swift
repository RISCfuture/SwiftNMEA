import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.42 GGA")
struct GGATests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -2)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GPSFix,
      fields: [
        hmsFractionFormatter.string(from: time),
        "3730.00", "N", "12115.00", "W",
        2, 11, 0.5,
        104.5, "M",
        1.1, "M",
        3.5, "0123"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GPSFix(
        position,
        actualTime,
        quality,
        numSatellites,
        HDOP,
        geoidalSeparation,
        DGPSAge,
        DGPSReferenceStationID
      ) = payload
    else {
      Issue.record("expected .GNSSAccuracyIntegrity, got \(payload)")
      return
    }

    #expect(position.latitude == .init(value: 37.5, unit: .degrees))
    #expect(position.longitude == .init(value: -121.25, unit: .degrees))
    #expect(position.altitude == .init(value: 104.5, unit: .meters))
    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(quality == .differentialSPS)
    #expect(numSatellites == 11)
    #expect(HDOP == 0.5)
    #expect(geoidalSeparation == .init(value: 1.1, unit: .meters))
    #expect(DGPSAge == .init(value: 3.5, unit: .seconds))
    #expect(DGPSReferenceStationID == 123)
  }

  @Test("parses a sentence from a STA8089FG")
  func parsesASentenceFromASTA8089FG() async throws {
    let parser = SwiftNMEA()
    let sentence =
      "$GPGGA,235944.000,0000.00000,N,00000.00000,E,0,00,99.0,100.00,M,0.0,M,,*61\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GPSFix(
        position,
        _,
        quality,
        numSatellites,
        HDOP,
        geoidalSeparation,
        DGPSAge,
        DGPSReferenceStationID
      ) = payload
    else {
      Issue.record("expected .GNSSAccuracyIntegrity, got \(payload)")
      return
    }

    #expect(position.latitude == .init(value: 0, unit: .degrees))
    #expect(position.longitude == .init(value: 0, unit: .degrees))
    #expect(quality == .invalid)
    #expect(numSatellites == 0)
    #expect(HDOP == 99.0)
    #expect(geoidalSeparation == .init(value: 0, unit: .meters))
    #expect(position.altitude == .init(value: 100, unit: .meters))
    #expect(DGPSAge == nil)
    #expect(DGPSReferenceStationID == nil)
  }
}
