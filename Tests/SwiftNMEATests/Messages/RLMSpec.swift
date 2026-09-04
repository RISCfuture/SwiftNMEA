import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.78 RLM` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .galileo,
      format: .returnLink,
      fields: [
        "ABCDEF012345678",
        hmsFractionFormatter.string(from: time),
        "2",
        "0123456789ABCDEF01234567"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .returnLink(beacon, actualTime, messageCode, messageBody) = payload
    else {
      Issue.record("expected .returnLink, got \(payload)")
      return
    }

    #expect(beacon == "ABCDEF012345678")
    #expect(abs(actualTime!.timeIntervalSince(time)) < 0.01)
    #expect(messageCode == .command)
    #expect(messageBody == Data(hex: "0123456789ABCDEF01234567")!)
  }

  @Test
  func `parses a sentence with no time of reception`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .galileo,
      format: .returnLink,
      fields: [
        "ABCDEF012345678",
        nil,
        "1",
        "ABCD"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .returnLink(beacon, actualTime, messageCode, messageBody) = payload
    else {
      Issue.record("expected .returnLink, got \(payload)")
      return
    }

    #expect(beacon == "ABCDEF012345678")
    #expect(actualTime == nil)
    #expect(messageCode == .acknowledgement)
    #expect(messageBody == Data(hex: "ABCD")!)
  }

  @Test
  func `throws an error for a beacon ID of the wrong length`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .galileo,
      format: .returnLink,
      fields: [
        "ABCDEF",
        nil,
        "1",
        "ABCD"
      ]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
  }
}
