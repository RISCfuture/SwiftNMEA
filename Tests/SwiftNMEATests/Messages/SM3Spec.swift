import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.94 SM3")
struct SM3Tests {
  @Test("parses a circular-area SafetyNET message")
  func parsesACircularAreaSafetyNETMessage() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected safetyNETCircularArea, got \(payload)")
      return
    }

    #expect(status == .complete)
    #expect(identification.uniqueMessageNumber == 42)
    #expect(identification.lesSequenceNumber == 10345)
    #expect(identification.lesID == 304)
    #expect(oceanRegion == .atlanticEast)
    #expect(priority == .urgency)
    #expect(serviceCode == .warning)
    #expect(presentationCode == .internationalAlphabet5)

    let expectedTime = calendar.date(
      from: .init(timeZone: .gmt, year: 2024, month: 6, day: 2, hour: 14, minute: 30)
    )
    #expect(receptionTime == expectedTime)

    #expect(abs(centre!.latitude.converted(to: .degrees).value - 56) < 0.001)
    #expect(abs(centre!.longitude.converted(to: .degrees).value - -34) < 0.001)
    #expect(abs(radius!.converted(to: .nauticalMiles).value - 35) < 0.001)
  }

  @Test("parses null centre, radius, and LES fields when MSI is incomplete")
  func parsesNullCentreRadiusAndLESFieldsWhenMSIIsIncomplete() async throws {
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

    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected safetyNETCircularArea, got \(payload)")
      return
    }

    #expect(status == .incomplete)
    #expect(identification.uniqueMessageNumber == 7)
    #expect(identification.lesSequenceNumber == nil)
    #expect(identification.lesID == nil)
    #expect(serviceCode == nil)
    #expect(centre == nil)
    #expect(radius == nil)
  }

  @Test("throws for a reserved ocean region code")
  func throwsForAReservedOceanRegionCode() async throws {
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
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
