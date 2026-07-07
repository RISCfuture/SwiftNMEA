import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.48 GSV")
struct GSVTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {

    // MARK: Setup

    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .GNSSSatellitesInView,
        fields: [
          2, 1, 7,
          "01", 11, 21, 31,
          "02", 12, 22, 32,
          "03", 13, 23, 33,
          "04", 14, 24, 34,
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .GNSSSatellitesInView,
        fields: [
          2, 2, 7,
          "05", 15, 25, 35,
          "06", 16, 26, 36,
          "07", 17, 27, 37,
          nil, nil, nil, nil,
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GLONASS,
        format: .GNSSSatellitesInView,
        fields: [
          1, 1, 4,
          "65", 15, 25, 35,
          "66", 16, 26, 36,
          "67", 17, 27, 37,
          "68", 18, 28, 38,
          2
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    let payload1 = try #require((messages[2] as? Message)?.payload)
    let payload2 = try #require((messages[4] as? Message)?.payload)

    // MARK: Message 1 (GPS)

    guard case let .GNSSSatellitesInView(satellites, total) = payload1 else {
      Issue.record("expected .GNSSSatellitesInView, got \(payload1)")
      return
    }
    #expect(total == 7)
    #expect(satellites.count == total)
    for i in 1...total {
      #expect(satellites[i - 1].id == .GPS(i, signal: .L1_CA))
      #expect(satellites[i - 1].position.elevation == .init(value: Double(10 + i), unit: .degrees))
      #expect(
        satellites[i - 1].position.azimuth == .init(degrees: Double(20 + i), reference: .true)
      )
      #expect(satellites[i - 1].SNR == 30 + i)
    }

    // MARK: Message 2 (GLONASS)

    guard case let .GNSSSatellitesInView(satellites, total) = payload2 else {
      Issue.record("expected .GNSSSatellitesInView, got \(payload2)")
      return
    }
    #expect(total == 4)
    #expect(satellites.count == total)
    for i in 1...total {
      #expect(satellites[i - 1].id == .GLONASS(64 + i, signal: .G1_P))
      #expect(satellites[i - 1].position.elevation == .init(value: Double(i + 14), unit: .degrees))
      #expect(
        satellites[i - 1].position.azimuth == .init(degrees: Double(i + 24), reference: .true)
      )
      #expect(satellites[i - 1].SNR == i + 34)
    }
  }

  @Test("derives the constellation from the talker and parses a hex signal ID")
  func derivesTheConstellationFromTheTalkerAndParsesAHexSignalID() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .beidou,
      format: .GNSSSatellitesInView,
      fields: [
        1, 1, 1,
        "05", 15, 25, 35,
        "C"  // BDS Signal ID B2Q (hex)
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let payload = (messages[1] as? Message)?.payload,
      case let .GNSSSatellitesInView(satellites, _) = payload
    else {
      Issue.record("expected .GNSSSatellitesInView, got \(messages[1])")
      return
    }
    #expect(satellites.count == 1)
    let expectedID: GNSS.SatelliteID = .beidou(5, signal: .B2Q)
    #expect(satellites[0].id == expectedID)
  }

  @Test("throws an error for an out-of-range signal ID")
  func throwsAnErrorForAnOutOfRangeSignalID() async throws {
    let parser = SwiftNMEA()
    // GPS signal IDs only range 0–8; hex "F" (15) is out of range.
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSSatellitesInView,
      fields: [
        1, 1, 1,
        "01", 11, 21, 31,
        "F"  // out-of-range GPS Signal ID (hex)
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
