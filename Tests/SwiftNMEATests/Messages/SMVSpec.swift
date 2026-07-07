import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.97 SMV")
struct SMVTests {
  // MARK: - .parse

  @Test("parses a single-sentence distress relay")
  func parsesASingleSentenceDistressRelay()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETVesselDistress,
      fields: [
        1, nil, 4, 123_123, 123_456_789, "TEST56",
        "1234.56", "N", "12345.67", "W",
        2018, 1, 22, 12, 34, "D"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .safetyNETVesselDistress(
        uniqueMessageNumber,
        identifier,
        mmsi,
        vesselName,
        position,
        positionTime,
        status
      ) = payload
    else {
      Issue.record("expected .safetyNETVesselDistress, got \(payload)")
      return
    }

    #expect(uniqueMessageNumber == 123_123)
    #expect(identifier == 4)
    #expect(mmsi == 123_456_789)
    #expect(vesselName == "TEST56")
    #expect(position == .init(latitude: (12, 34.56), longitude: (-123, 45.67)))
    let components = DateComponents(
      timeZone: .gmt,
      year: 2018,
      month: 1,
      day: 22,
      hour: 12,
      minute: 34
    )
    #expect(positionTime == calendar.date(from: components))
    #expect(status == .distressActive)
  }

  @Test("parses a single-sentence cancellation with null optional fields")
  func parsesASingleSentenceCancellationWithNullOptionalFields() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETVesselDistress,
      fields: [
        1, nil, 5, 12, nil, nil,
        nil, nil, nil, nil,
        nil, nil, nil, nil, nil, "C"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .safetyNETVesselDistress(
        uniqueMessageNumber,
        identifier,
        mmsi,
        vesselName,
        position,
        positionTime,
        status
      ) = payload
    else {
      Issue.record("expected .safetyNETVesselDistress, got \(payload)")
      return
    }

    #expect(uniqueMessageNumber == 12)
    #expect(identifier == 5)
    #expect(mmsi == nil)
    #expect(vesselName == nil)
    #expect(position == nil)
    #expect(positionTime == nil)
    #expect(status == .distressCancelled)
  }

  @Test("assembles a two-sentence message with position and name in separate sentences")
  func assemblesATwoSentenceMessageWithPositionAndNameInSeparateSentences() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "$CSSMV,2,1,5,12,123456789,,1234.56,N,12345.67,W,2018,01,23,12,34,D"),
      applyChecksum(to: "$CSSMV,2,2,5,12,123456789,MAXIMUM LENGTH FOR VESSEL NAME,,,,,,,,,,D")
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // two echoed sentences, then the assembled message on the last sentence
    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    guard
      case let .safetyNETVesselDistress(
        uniqueMessageNumber,
        identifier,
        mmsi,
        vesselName,
        position,
        _,
        status
      ) = payload
    else {
      Issue.record("expected .safetyNETVesselDistress, got \(payload)")
      return
    }

    #expect(uniqueMessageNumber == 12)
    #expect(identifier == 5)
    #expect(mmsi == 123_456_789)
    #expect(vesselName == "MAXIMUM LENGTH FOR VESSEL NAME")
    #expect(position == .init(latitude: (12, 34.56), longitude: (-123, 45.67)))
    #expect(status == .distressActive)
  }

  @Test("throws an error for a null sentence number in a multi-sentence message")
  func throwsAnErrorForANullSentenceNumberInAMultiSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETVesselDistress,
      fields: [
        2, nil, 4, 123_123, 123_456_789, "TEST56",
        "1234.56", "N", "12345.67", "W",
        2018, 1, 22, 12, 34, "D"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 1)
  }

  @Test("throws an error for an unknown distress status value")
  func throwsAnErrorForAnUnknownDistressStatusValue() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commSatellite,
      format: .safetyNETVesselDistress,
      fields: [
        1, nil, 4, 123_123, 123_456_789, "TEST56",
        "1234.56", "N", "12345.67", "W",
        2018, 1, 22, 12, 34, "X"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .unknownValue)
  }
}
