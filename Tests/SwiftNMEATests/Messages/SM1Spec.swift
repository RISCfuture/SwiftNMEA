import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.92 SM1")
struct SM1Tests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETAllShips,
      fields: ["A", 1234, "010345", "104", 1, 2, 31, "00", 2024, 6, 2, 13, 56, 5]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETAllShips, got \(payload)")
      return
    }

    #expect(status == .complete)
    #expect(identification.uniqueMessageNumber == 1234)
    #expect(identification.lesSequenceNumber == 10345)
    #expect(identification.lesID == 104)
    #expect(oceanRegion == .atlanticEast)
    #expect(priority == .urgency)
    #expect(serviceCode == .navAreaWarning)
    #expect(presentationCode == .internationalAlphabet5)
    let components = DateComponents(
      timeZone: .gmt,
      year: 2024,
      month: 6,
      day: 2,
      hour: 13,
      minute: 56
    )
    #expect(receptionTime == calendar.date(from: components))
    #expect(addressCode == 5)
  }

  @Test("parses null sequence, LES ID, service, and address fields")
  func parsesNullSequenceLESIDServiceAndAddressFields() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETAllShips,
      fields: ["V", 7, nil, nil, 9, 1, nil, "00", 2024, 12, 31, 0, 0, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETAllShips, got \(payload)")
      return
    }

    #expect(status == .incomplete)
    #expect(identification.uniqueMessageNumber == 7)
    #expect(identification.lesSequenceNumber == nil)
    #expect(identification.lesID == nil)
    #expect(oceanRegion == .all)
    #expect(serviceCode == nil)
    #expect(addressCode == nil)
  }

  @Test("throws an error for a reserved ocean region code")
  func throwsAnErrorForAReservedOceanRegionCode() async throws {
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
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
