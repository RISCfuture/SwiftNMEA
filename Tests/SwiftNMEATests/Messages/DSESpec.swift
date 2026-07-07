import Foundation
import Testing

@testable import NMEACommon
@testable import SwiftNMEA

@Suite("8.3.30 DSE")
struct DSETests {
  // MARK: - .parse

  @Test("parses a query and a reply")
  func parsesAQueryAndAReply() async throws {
    let parser = SwiftNMEA()

    // MARK: Setup

    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          3, 1, "A", 1_234_567_890,
          "00", "23451234",
          "01", "015500"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          1, 1, "Q", 9_876_543_210,
          "00", nil,
          "05", nil
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          3, 2, "A", 1_234_567_890,
          "02", "C26",
          "02", "0224",
          "03", "1801"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          3, 3, nil, nil,
          "04", "ABC'123",
          "05", "123456781324576802241801",
          "06", "0112"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // MARK: - Message 1

    #expect(messages.count == 6)
    let payload1 = try #require((messages[2] as? Message)?.payload)
    let payload2 = try #require((messages[5] as? Message)?.payload)
    guard case let .DSE(type, MMSI, data) = payload2 else {
      Issue.record("expected .DSE, got \(payload2)")
      return
    }

    #expect(type == .automatic)
    #expect(MMSI == 123_456_789)
    #expect(data.count == 8)

    // MARK: data 0 (enhancedPositionResolution)

    guard case let .enhancedPositionResolution(content) = data[0] else {
      Issue.record("expected .enhancedPositionResolution, got \(data[0])")
      return
    }
    guard case let .data(enhancement) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    let testPos = Position(latitude: 37.5, longitude: -121.25)
    let refinedPos = enhancement.refine(position: testPos)
    #expect(abs(refinedPos.latitude.converted(to: .degrees).value - 37.5039083333) < 0.0001)
    #expect(abs(refinedPos.longitude.converted(to: .degrees).value - (-121.2520566667)) < 0.0001)

    // MARK: data 1 (positionSourceDatum)

    guard case let .positionSourceDatum(content) = data[1] else {
      Issue.record("expected .positionSourceDatum, got \(data[1])")
      return
    }
    guard case let .data(sourceDatum) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(sourceDatum.source == .differentialGPS)
    #expect(sourceDatum.fixResolution == 5.5)
    #expect(sourceDatum.datum == .WGS84)

    // MARK: data 2 (speed noDataAvailable)

    guard case let .speed(content) = data[2] else {
      Issue.record("expected .speed, got \(data[2])")
      return
    }
    #expect(content == .noDataAvailable)

    // MARK: data 3 (speed)

    guard case let .speed(content) = data[3] else {
      Issue.record("expected .speed, got \(data[3])")
      return
    }
    guard case let .data(speed) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(speed.measurement == .init(value: 22.4, unit: .knots))

    // MARK: data 4 (course)

    guard case let .course(content) = data[4] else {
      Issue.record("expected .course, got \(data[4])")
      return
    }
    guard case let .data(course) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(course.measurement == .init(value: 180.1, unit: .degrees))

    // MARK: data 5 (additional ID)

    guard case let .additionalID(content) = data[5] else {
      Issue.record("expected .additionalID, git \(data[5])")
      return
    }
    guard case let .data(ID) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(ID.value == "ABC,123")

    // MARK: data 6 (geo area)

    guard case let .enhnancedGeoArea(content) = data[6] else {
      Issue.record("expected .enhnancedGeoArea, git \(data[6])")
      return
    }
    guard case let .data(enhancement) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(enhancement.latitudeRefinement == .init(value: 12.34, unit: .arcMinutes))
    #expect(enhancement.longitudeRefinement == .init(value: 56.78, unit: .arcMinutes))
    #expect(enhancement.deltaLatRefinement == .init(value: 13.24, unit: .arcMinutes))
    #expect(enhancement.deltaLonRefinement == .init(value: 57.68, unit: .arcMinutes))
    #expect(enhancement.speed == .init(value: 22.4, unit: .knots))
    #expect(enhancement.course == .init(value: 180.1, unit: .degrees))
    let area = GeoArea(latitude: 37, longitude: -121, deltaLat: 3, deltaLon: 4)
    let refinedArea = enhancement.refine(area: area)
    #expect(abs(refinedArea.latitude.converted(to: .degrees).value - 37.2056666667) < 0.0001)
    #expect(abs(refinedArea.longitude.converted(to: .degrees).value - (-121.9463333333)) < 0.0001)
    #expect(abs(refinedArea.deltaLat.converted(to: .degrees).value - 3.2206666667) < 0.0001)
    #expect(abs(refinedArea.deltaLon.converted(to: .degrees).value - 4.9613333333) < 0.0001)

    // MARK: data 7 (souls onboard)

    guard case let .personsOnboard(content) = data[7] else {
      Issue.record("expected .personsOnboard, got \(data[7])")
      return
    }
    guard case let .data(souls) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(souls.value == 112)

    // MARK: - Message 2

    guard case let .DSE(type, MMSI, data) = payload1 else {
      Issue.record("expected .DSE, got \(payload1)")
      return
    }
    #expect(type == .query)
    #expect(MMSI == 987_654_321)
    #expect(data.count == 2)

    // MARK: data 0

    guard case let .enhancedPositionResolution(content) = data[0] else {
      Issue.record("expected .enhancedPositionResolution, got \(data[0])")
      return
    }
    #expect(content == .dataRequest)

    // MARK: data 1

    guard case let .enhnancedGeoArea(content) = data[1] else {
      Issue.record("expected .enhancedPositionResolution, got \(data[1])")
      return
    }
    #expect(content == .dataRequest)
  }

  @Test("throws an error for a missing field")
  func throwsAnErrorForAMissingField() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          2, 1, "A", nil,
          "00", "23451234",
          "01", "015500"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          2, 2, "A", 1_234_567_890,
          "02", "C26",
          "02", "0224",
          "03", "1801"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 3)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          2, 1, "A", 1_234_567_890,
          "00", "23451234",
          "01", "015500"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          2, 3, "A", 1_234_567_890,
          "02", "C26",
          "02", "0224",
          "03", "1801"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$CVDSE,1,1,A,3601234560,00,12345678*0C\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard case let .DSE(type, MMSI, data) = message.payload else {
      Issue.record("expected .DSE, got \(message)")
      return
    }

    #expect(type == .automatic)
    #expect(MMSI == 360_123_456)

    #expect(data.count == 1)
    guard case let .enhancedPositionResolution(value) = data[0] else {
      Issue.record("expected .enhancedPositionResolution, got \(data[0])")
      return
    }
    guard case let .data(refinement) = value else {
      Issue.record("expected .data, got \(value)")
      return
    }
    #expect(abs(refinement.latitudeRefinement.value - 0.1234) < 0.000001)
    #expect(abs(refinement.longitudeRefinement.value - 0.5678) < 0.000001)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()

    // MARK: Setup

    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          3, 1, "A", 1_234_567_890,
          "00", "23451234",
          "01", "015500"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .commDSC,
        format: .DSE,
        fields: [
          3, 2, "A", 1_234_567_890,
          "02", "C26",
          "02", "0224",
          "03", "1801"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 2)
    let messages = try await parser.flush(includeIncomplete: true)

    // MARK: - Message 1

    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    guard case let .DSE(type, MMSI, data) = message.payload else {
      Issue.record("expected .DSE, got \(message)")
      return
    }

    #expect(type == .automatic)
    #expect(MMSI == 123_456_789)
    #expect(data.count == 5)

    // MARK: data 0 (enhancedPositionResolution)

    guard case let .enhancedPositionResolution(content) = data[0] else {
      Issue.record("expected .enhancedPositionResolution, got \(data[0])")
      return
    }
    guard case let .data(enhancement) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    let testPos = Position(latitude: 37.5, longitude: -121.25)
    let refinedPos = enhancement.refine(position: testPos)
    #expect(abs(refinedPos.latitude.converted(to: .degrees).value - 37.5039083333) < 0.0001)
    #expect(abs(refinedPos.longitude.converted(to: .degrees).value - (-121.2520566667)) < 0.0001)

    // MARK: data 1 (positionSourceDatum)

    guard case let .positionSourceDatum(content) = data[1] else {
      Issue.record("expected .positionSourceDatum, got \(data[1])")
      return
    }
    guard case let .data(sourceDatum) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(sourceDatum.source == .differentialGPS)
    #expect(sourceDatum.fixResolution == 5.5)
    #expect(sourceDatum.datum == .WGS84)

    // MARK: data 2 (speed noDataAvailable)

    guard case let .speed(content) = data[2] else {
      Issue.record("expected .speed, got \(data[2])")
      return
    }
    #expect(content == .noDataAvailable)

    // MARK: data 3 (speed)

    guard case let .speed(content) = data[3] else {
      Issue.record("expected .speed, got \(data[3])")
      return
    }
    guard case let .data(speed) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(speed.measurement == .init(value: 22.4, unit: .knots))

    // MARK: data 4 (course)

    guard case let .course(content) = data[4] else {
      Issue.record("expected .course, got \(data[4])")
      return
    }
    guard case let .data(course) = content else {
      Issue.record("expected .data, got \(content)")
      return
    }
    #expect(course.measurement == .init(value: 180.1, unit: .degrees))
  }
}
