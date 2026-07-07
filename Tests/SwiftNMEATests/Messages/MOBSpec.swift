import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.64 MOB")
struct MOBTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .manOverboard,
      fields: [
        "000FF",
        "A",
        "120000",
        1,
        3,
        "120530",
        "3730.00", "N", "12115.00", "W",
        90,
        5,
        123_456_789,
        0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .manOverboard(
        emitterID,
        status,
        activationTime,
        positionSource,
        daysSinceActivation,
        positionTime,
        position,
        courseOverGround,
        speedOverGround,
        MMSI,
        batteryStatus
      ) = payload
    else {
      Issue.record("expected .manOverboard, got \(payload)")
      return
    }

    #expect(emitterID == 0xFF)
    #expect(status == .activated)
    #expect(positionSource == .reportedByEmitter)
    #expect(daysSinceActivation == 3)
    #expect(position.latitude == .init(value: 37.5, unit: .degrees))
    #expect(position.longitude == .init(value: -121.25, unit: .degrees))
    #expect(courseOverGround.angle == .init(value: 90, unit: .degrees))
    #expect(courseOverGround.reference == .true)
    #expect(speedOverGround == .init(value: 5, unit: .knots))
    #expect(MMSI == 123_456_789)
    #expect(batteryStatus == .good)

    let activation = Calendar.current.dateComponents(in: .gmt, from: activationTime)
    #expect(activation.hour == 12)
    #expect(activation.minute == 0)
    #expect(activation.second == 0)

    let positioned = Calendar.current.dateComponents(in: .gmt, from: positionTime)
    #expect(positioned.hour == 12)
    #expect(positioned.minute == 5)
    #expect(positioned.second == 30)
  }

  @Test("parses a sentence with unavailable values")
  func parsesASentenceWithUnavailableValues()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .manOverboard,
      fields: [
        nil,
        "T",
        "010203",
        0,
        0,
        "010203",
        "3730.00", "N", "12115.00", "W",
        0,
        0,
        nil,
        nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .manOverboard(
        emitterID,
        status,
        _,
        positionSource,
        _,
        _,
        _,
        _,
        _,
        MMSI,
        batteryStatus
      ) = payload
    else {
      Issue.record("expected .manOverboard, got \(payload)")
      return
    }

    #expect(emitterID == nil)
    #expect(status == .test)
    #expect(positionSource == .estimatedByVessel)
    #expect(MMSI == nil)
    #expect(batteryStatus == nil)
  }

  @Test("throws an error for an unknown position source")
  func throwsAnErrorForAnUnknownPositionSource() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .manOverboard,
      fields: [
        "000FF",
        "A",
        "120000",
        7,
        3,
        "120530",
        "3730.00", "N", "12115.00", "W",
        90,
        5,
        123_456_789,
        0
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
