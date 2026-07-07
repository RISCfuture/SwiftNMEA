import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.93 SM2")
struct SM2Tests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETCoastalWarningArea, got \(payload)")
      return
    }

    #expect(status == .complete)
    #expect(identification.uniqueMessageNumber == 42)
    #expect(identification.lesSequenceNumber == 10345)
    #expect(identification.lesID == 104)
    #expect(oceanRegion == .atlanticEast)
    #expect(priority == .safety)
    #expect(serviceCode == .coastalWarning)
    #expect(presentationCode == .internationalAlphabet5)
    let components = DateComponents(
      timeZone: .gmt,
      year: 2024,
      month: 6,
      day: 27,
      hour: 13,
      minute: 56,
      second: 0
    )
    #expect(receptionTime == calendar.date(from: components))
    #expect(warningArea == 5)
    #expect(warningAreaLetter == "C")
    #expect(subjectIndicator == .navigationalWarnings)
  }

  @Test("parses a sentence with unavailable values")
  func parsesASentenceWithUnavailableValues() async throws {
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

    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .safetyNETCoastalWarningArea, got \(payload)")
      return
    }

    #expect(status == .incomplete)
    #expect(identification.lesSequenceNumber == nil)
    #expect(identification.lesID == nil)
    #expect(serviceCode == nil)
    #expect(warningArea == nil)
    #expect(warningAreaLetter == nil)
    #expect(subjectIndicator == nil)
  }

  @Test("throws an error for an out-of-range NAVAREA number")
  func throwsAnErrorForAnOutOfRangeNAVAREANumber() async throws {
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
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
  }

  @Test("throws an error for an out-of-range reception date")
  func throwsAnErrorForAnOutOfRangeReceptionDate() async throws {
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
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badDate)
  }
}
