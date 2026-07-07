import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.38 GBS")
struct GBSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSFaultDetection,
      fields: [
        hmsFractionFormatter.string(from: time), 1.2, 3.4, 5.6,
        35, 0.5, 1.5, 0.75,
        1, 5
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSSFaultDetection(
        actualTime,
        latitudeError,
        longitudeError,
        altitudeError,
        failedSatellite,
        missProbability,
        biasEstimate,
        biasEstimateStddev
      ) =
        payload
    else {
      Issue.record("expected .GNSSFaultDetection, got \(payload)")
      return
    }

    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(latitudeError == .init(value: 1.2, unit: .meters))
    #expect(longitudeError == .init(value: 3.4, unit: .meters))
    #expect(altitudeError == .init(value: 5.6, unit: .meters))

    #expect(failedSatellite.PRN == 122)
    #expect(failedSatellite.isAugmented)
    guard case let .GPS(id, signal) = failedSatellite else {
      Issue.record("expected .GPS, got \(failedSatellite)")
      return
    }
    #expect(id == 35)
    #expect(signal == .L2C_M)

    #expect(missProbability == 0.5)
    #expect(biasEstimate == .init(value: 1.5, unit: .meters))
    #expect(biasEstimateStddev == .init(value: 0.75, unit: .meters))
  }

  @Test("throws an error for an out-of-range hex system ID")
  func throwsAnErrorForAnOutOfRangeHexSystemID() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSFaultDetection,
      fields: [
        hmsFractionFormatter.string(from: time), 1.2, 3.4, 5.6,
        35, 0.5, 1.5, 0.75,
        "FFFFFFFFFFFFFFFF", 5
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
    #expect(error.fieldNumber == 8)
  }
}
