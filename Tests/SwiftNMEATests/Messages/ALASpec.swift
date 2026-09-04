import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.12 ALA` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -2000)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .detailAlarm,
      fields: [
        hmsFractionFormatter.string(from: time),
        "SG", nil, 3, 900, "H", "V", "example alarm"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .detailAlarm(
        actualTime,
        alarm,
        instance,
        condition,
        state,
        description
      ) =
        payload
    else {
      Issue.record("expected .detailAlarm, got \(payload)")
      return
    }
    #expect(abs(try #require(actualTime).timeIntervalSince(time)) < 0.01)
    #expect(alarm == .steeringGear(subsystem: .none(code: 900)))
    #expect(instance == 3)
    #expect(condition == .high)
    #expect(state == .notAcknowledged)
    #expect(description == "example alarm")
  }

  @Test
  func `parses a DC propulsion motor overspeed alarm (EP/PD code 3)`() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -120)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .detailAlarm,
      fields: [
        hmsFractionFormatter.string(from: time),
        "EP", "PD", 1, 3, "H", "V", "overspeed"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .detailAlarm(_, alarm, _, _, _, _) = payload else {
      Issue.record("expected .detailAlarm, got \(payload)")
      return
    }
    #expect(alarm == .electricPlant(subsystem: .DCPropulsionMotor(type: .overspeed)))
  }

  @Test
  func `does not recognize the removed DC propulsion motor code 8`() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -120)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .detailAlarm,
      fields: [
        hmsFractionFormatter.string(from: time),
        "EP", "PD", 1, 8, "H", "V", "removed code"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .detailAlarm(_, alarm, _, _, _, _) = payload else {
      Issue.record("expected .detailAlarm, got \(payload)")
      return
    }
    #expect(alarm == .electricPlant(subsystem: .DCPropulsionMotor(type: nil)))
  }
}
