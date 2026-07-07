import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.7 ACN")
struct ACNTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -2000)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommand,
      fields: [
        hmsFractionFormatter.string(from: time),
        "ABC", 2456789, 42, "C", "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertCommand(actualTime, alert, command) = payload else {
      Issue.record("expected .alertCommand, got \(payload)")
      return
    }
    #expect(abs(try #require(actualTime).timeIntervalSince(time)) < 0.01)
    #expect(alert == .init(manufacturerMnemonic: "ABC", identifier: 2_456_789, instance: 42))
    #expect(command == .acknowledge)
  }

  @Test("parses a sentence with null optional fields")
  func parsesASentenceWithNullOptionalFields() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommand,
      fields: [nil, nil, 1, nil, "C", "Q"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertCommand(actualTime, alert, command) = payload else {
      Issue.record("expected .alertCommand, got \(payload)")
      return
    }
    #expect(actualTime == nil)
    #expect(alert == .init(manufacturerMnemonic: nil, identifier: 1, instance: nil))
    #expect(command == .requestRepeat)
  }

  @Test("throws an error when the sentence status flag is not \"C\"")
  func throwsAnErrorWhenTheSentenceStatusFlagIsNotC() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommand,
      fields: [nil, nil, 1, 2, "R", "A"]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
  }

  @Test("throws an error for acknowledge of alert instance 0")
  func throwsAnErrorForAcknowledgeOfAlertInstance0() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommand,
      fields: [nil, nil, 1, 0, "C", "A"]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
  }
}
