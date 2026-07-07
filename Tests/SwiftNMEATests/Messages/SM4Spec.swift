import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.95 SM4")
struct SM4Tests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETRectangularArea, got \(payload)")
      return
    }

    #expect(status == .complete)
    #expect(identification.uniqueMessageNumber == 5213)
    #expect(identification.lesSequenceNumber == 798)
    #expect(identification.lesID == 798)
    #expect(oceanRegion == .atlanticWest)
    #expect(priority == .distress)
    #expect(serviceCode == .navigationalWarning)
    #expect(presentationCode == .internationalAlphabet5)

    let components = DateComponents(
      timeZone: .gmt,
      year: 2012,
      month: 4,
      day: 5,
      hour: 14,
      minute: 30
    )
    #expect(receptionTime == calendar.date(from: components))

    #expect(abs(southWestCorner!.latitude.converted(to: .degrees).value - 60) < 0.001)
    #expect(abs(southWestCorner!.longitude.converted(to: .degrees).value - -10) < 0.001)
    #expect(latitudeExtent == .init(value: 30, unit: .degrees))
    #expect(longitudeExtent == .init(value: 25, unit: .degrees))
  }

  @Test("parses null service, position, and extent fields")
  func parsesNullServicePositionAndExtentFields() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETRectangularArea, got \(payload)")
      return
    }

    #expect(status == .incomplete)
    #expect(identification.uniqueMessageNumber == 7)
    #expect(identification.lesSequenceNumber == nil)
    #expect(identification.lesID == nil)
    #expect(oceanRegion == .all)
    #expect(serviceCode == nil)
    #expect(southWestCorner == nil)
    #expect(latitudeExtent == nil)
    #expect(longitudeExtent == nil)
  }

  @Test("throws an error for an invalid service code")
  func throwsAnErrorForAnInvalidServiceCode() async throws {
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
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
