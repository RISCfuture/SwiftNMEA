import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.55 HRM` {
  @Test
  func `parses a sentence with all values`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .heelRollMeasurement,
      fields: [-2.5, 8.0, 5.0, 6.0, "A", 7.0, 9.0, "123456", 15, 6, 2024, 30.0, "R"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .heelRollMeasurement(
        heelAngle,
        rollPeriod,
        rollAmplitudePort,
        rollAmplitudeStarboard,
        isValid,
        peakHoldPort,
        peakHoldStarboard,
        peakHoldResetTime,
        alertThreshold,
        status
      ) = payload
    else {
      Issue.record("expected .heelRollMeasurement, got \(payload)")
      return
    }

    #expect(heelAngle == .init(value: -2.5, unit: .degrees))
    #expect(rollPeriod == .init(value: 8.0, unit: .seconds))
    #expect(rollAmplitudePort == .init(value: 5.0, unit: .degrees))
    #expect(rollAmplitudeStarboard == .init(value: 6.0, unit: .degrees))
    #expect(isValid)
    #expect(peakHoldPort == .init(value: 7.0, unit: .degrees))
    #expect(peakHoldStarboard == .init(value: 9.0, unit: .degrees))
    #expect(alertThreshold == .init(value: 30.0, unit: .degrees))
    #expect(status == .reply)

    let expectedReset = calendar.date(
      from: .init(
        timeZone: .gmt,
        year: 2024,
        month: 6,
        day: 15,
        hour: 12,
        minute: 34,
        second: 56
      )
    )
    #expect(peakHoldResetTime == expectedReset)
  }

  @Test
  func `parses a sentence with unavailable peak hold values`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .heelRollMeasurement,
      fields: [-2.5, 8.0, 5.0, 6.0, "A", nil, nil, nil, nil, nil, nil, nil, "R"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .heelRollMeasurement(
        _,
        _,
        _,
        _,
        _,
        peakHoldPort,
        peakHoldStarboard,
        peakHoldResetTime,
        alertThreshold,
        _
      ) = payload
    else {
      Issue.record("expected .heelRollMeasurement, got \(payload)")
      return
    }

    #expect(peakHoldPort == nil)
    #expect(peakHoldStarboard == nil)
    #expect(peakHoldResetTime == nil)
    #expect(alertThreshold == nil)
  }

  @Test
  func `throws when the sentence status flag is missing`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .heelRollMeasurement,
      fields: [-2.5, 8.0, 5.0, 6.0, "A", nil, nil, nil, nil, nil, nil, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
  }
}
