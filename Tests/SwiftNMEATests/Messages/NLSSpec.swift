import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.71 NLS")
struct NLSTests {
  @Test("parses a single-sentence message")
  func parsesASingleSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .navLightController,
      format: .navigationLightStatus,
      fields: [
        1, 1, 96, 2,
        12, 2, 27,
        3, 1, nil
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .navigationLightStatus(id, lights) = payload else {
      Issue.record("expected .navigationLightStatus, got \(payload)")
      return
    }

    #expect(id == 96)
    #expect(lights.count == 2)
    #expect(lights[0].identifier == 12)
    #expect(lights[0].status == .on)
    #expect(lights[0].remainingWorkingHours == .estimate(.init(value: 2_700, unit: .hours)))
    #expect(lights[1].identifier == 3)
    #expect(lights[1].status == .off)
    #expect(lights[1].remainingWorkingHours == nil)
  }

  @Test("parses a multi-sentence message")
  func parsesAMultiSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .navLightController,
        format: .navigationLightStatus,
        fields: [
          2, 1, 96, 4,
          12, 2, nil,
          3, 1, nil,
          471, 3, 4,
          6, 3, nil
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .navLightController,
        format: .navigationLightStatus,
        fields: [
          2, 2, 96, 2,
          2, 2, nil,
          33, 2, nil
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // two echoed sentences, one completed Message after the second
    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    guard case let .navigationLightStatus(id, lights) = payload else {
      Issue.record("expected .navigationLightStatus, got \(payload)")
      return
    }

    #expect(id == 96)
    #expect(lights.count == 6)
    #expect(lights.map(\.identifier) == [12, 3, 471, 6, 2, 33])
    #expect(lights[2].remainingWorkingHours == .estimate(.init(value: 400, unit: .hours)))
    #expect(lights[5].status == .on)
  }

  @Test("parses unavailable status and remaining hours as nil")
  func parsesUnavailableStatusAndRemainingHoursAsNil() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .navLightController,
      format: .navigationLightStatus,
      fields: [
        1, 1, 0, 1,
        5, nil, nil
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .navigationLightStatus(_, lights) = payload else {
      Issue.record("expected .navigationLightStatus, got \(payload)")
      return
    }

    #expect(lights.count == 1)
    #expect(lights[0].identifier == 5)
    #expect(lights[0].status == nil)
    #expect(lights[0].remainingWorkingHours == nil)
  }

  @Test("represents more than 9 800 remaining hours")
  func representsMoreThan9800RemainingHours() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .navLightController,
      format: .navigationLightStatus,
      fields: [
        1, 1, 1, 1,
        7, 2, 99
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let payload = (messages[1] as? Message)?.payload,
      case let .navigationLightStatus(_, lights) = payload
    else {
      Issue.record("expected .navigationLightStatus, got \(messages[1])")
      return
    }
    #expect(lights[0].remainingWorkingHours == .moreThan9800Hours)
  }

  @Test("throws an error for an unknown light status")
  func throwsAnErrorForAnUnknownLightStatus() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .navLightController,
      format: .navigationLightStatus,
      fields: [
        1, 1, 1, 1,
        8, 7, nil
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
