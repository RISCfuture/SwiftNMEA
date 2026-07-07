import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.121 VSD")
struct VSDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: 259_200)
    let timeComponents = Calendar.current.dateComponents(in: .gmt, from: time)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISVoyageData,
      fields: [
        51, 25.5, 8191, "KOAK",
        hmsFractionFormatter.string(from: time), dayFormatter.string(from: time),
        monthFormatter.string(from: time),
        0, 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .AISVoyageData(
        shipType,
        maxDraft,
        soulsOnboard,
        destination,
        destinationETA,
        navStatus,
        regionalFlags
      ) = payload
    else {
      Issue.record("expected .AISVoyageData, got \(payload)")
      return
    }

    #expect(shipType == .SAR)
    #expect(maxDraft == .available(.init(value: 25.5, unit: .meters)))
    #expect(soulsOnboard == .available(8191))
    #expect(destination == .available("KOAK"))
    #expect(destinationETA.month == .available(timeComponents.month!))
    #expect(destinationETA.day == .available(timeComponents.day!))
    #expect(destinationETA.hour == .available(timeComponents.hour!))
    #expect(destinationETA.minute == .available(timeComponents.minute!))
    #expect(navStatus == .underway)
    #expect(regionalFlags == 0)
  }

  @Test("parses unavailable values")
  func parsesUnavailableValues() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISVoyageData,
      fields: [
        nil, 0.0, 0, "@@@@@@@@@@@@@@@@@@@@",
        "246000.00", "00", "00",
        nil, 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .AISVoyageData(
        shipType,
        maxDraft,
        soulsOnboard,
        destination,
        destinationETA,
        navStatus,
        regionalFlags
      ) = payload
    else {
      Issue.record("expected .AISVoyageData, got \(payload)")
      return
    }

    #expect(shipType == nil)
    #expect(maxDraft == .unavailable)
    #expect(soulsOnboard == .unavailable)
    #expect(destination == .unavailable)
    #expect(destinationETA.month == .unavailable)
    #expect(destinationETA.day == .unavailable)
    #expect(destinationETA.hour == .unavailable)
    #expect(destinationETA.minute == .unavailable)
    #expect(navStatus == nil)
    #expect(regionalFlags == 0)
  }

  @Test("parses a navigational status added in M.1371-6")
  func parsesANavigationalStatusAddedInM13716() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: 259_200)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISVoyageData,
      fields: [
        51, 25.5, 8191, "KOAK",
        hmsFractionFormatter.string(from: time), dayFormatter.string(from: time),
        monthFormatter.string(from: time),
        14, 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let payload = (messages[1] as? Message)?.payload,
      case let .AISVoyageData(_, _, _, _, _, navStatus, _) = payload
    else {
      Issue.record("expected .AISVoyageData, got \(messages[1])")
      return
    }
    #expect(navStatus == .activeEmergencyBeacon)
  }
}
