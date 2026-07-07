import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.81 RMC")
struct RMCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -0.5)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSMinimumData,
      fields: [
        hmsFractionFormatter.string(from: time),
        "A",
        "3630.00", "N", "12215.00", "W",
        12.3, 123.4,
        dateFormatter.string(from: time),
        1.2, "W",
        "D", "S"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSSMinimumData(
        actualTime,
        isValid,
        position,
        speed,
        course,
        magneticVariation,
        mode,
        status
      ) = payload
    else {
      Issue.record("expected .GNSSMinimumData, got \(payload)")
      return
    }

    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(isValid)
    #expect(position?.latitude == .init(value: 36.5, unit: .degrees))
    #expect(position?.longitude == .init(value: -122.25, unit: .degrees))
    #expect(speed == .init(value: 12.3, unit: .knots))
    #expect(course?.angle == .init(value: 123.4, unit: .degrees))
    #expect(course?.reference == .true)
    #expect(magneticVariation == .init(value: -1.2, unit: .degrees))
    #expect(mode == .differential)
    #expect(status == .safe)
  }

  @Test("parses a sentence with null fields when data is temporarily unavailable")
  func parsesASentenceWithNullFieldsWhenDataIsTemporarilyUnavailable() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSMinimumData,
      fields: [
        nil,
        "V",
        nil, nil, nil, nil,
        nil, nil,
        nil,
        nil, nil,
        "N", "V"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSSMinimumData(
        actualTime,
        isValid,
        position,
        speed,
        course,
        magneticVariation,
        mode,
        status
      ) = payload
    else {
      Issue.record("expected .GNSSMinimumData, got \(payload)")
      return
    }

    #expect(actualTime == nil)
    #expect(!isValid)
    #expect(position == nil)
    #expect(speed == nil)
    #expect(course == nil)
    #expect(magneticVariation == nil)
    #expect(mode == .invalid)
    #expect(status == .notInUse)
  }
}
