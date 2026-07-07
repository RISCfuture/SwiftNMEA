import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.17 ARC")
struct ARCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -12)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommandRefused,
      fields: [
        hmsFractionFormatter.string(from: time),
        "NMA", 2456789, 12, "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertCommandRefused(actualTime, alert, refusedCommand) = payload else {
      Issue.record("expected .alertCommandRefused, got \(payload)")
      return
    }

    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(alert.manufacturerMnemonic == "NMA")
    #expect(alert.identifier == 2_456_789)
    #expect(alert.instance == 12)
    #expect(refusedCommand == .acknowledge)
  }

  @Test("parses a sentence with null optional fields")
  func parsesASentenceWithNullOptionalFields() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommandRefused,
      fields: [
        nil, nil, 245, nil, "S"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertCommandRefused(actualTime, alert, refusedCommand) = payload else {
      Issue.record("expected .alertCommandRefused, got \(payload)")
      return
    }

    #expect(actualTime == nil)
    #expect(alert.manufacturerMnemonic == nil)
    #expect(alert.identifier == 245)
    #expect(alert.instance == nil)
    #expect(refusedCommand == .temporarySilence)
  }

  @Test("throws an error for an invalid refused command")
  func throwsAnErrorForAnInvalidRefusedCommand() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertCommandRefused,
      fields: [
        nil, nil, 245, 1, "Z"
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
    let error = try #require(messages.compactMap { $0 as? MessageError }.first)
    #expect(error.type == .unknownValue)
  }
}
