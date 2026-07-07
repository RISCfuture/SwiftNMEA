import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.33 EPV")
struct EPVTests {
  @Test("parses a command sentence")
  func parsesACommandSentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentProperty,
      fields: ["C", "AI", "503123450", 101, "38400"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .equipmentProperty(
          type: .command,
          reference: .init(type: .automaticID, uniqueID: "503123450"),
          property: .init(rawValue: 101),
          value: "38400"
        )
    )
  }

  @Test("parses a report sentence")
  func parsesAReportSentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .equipmentProperty,
      fields: ["R", "AI", "503123450", 101, "38400"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .equipmentProperty(
          type: .reply,
          reference: .init(type: .automaticID, uniqueID: "503123450"),
          property: .init(rawValue: 101),
          value: "38400"
        )
    )
  }

  @Test("decodes escaped reserved characters in the value")
  func decodesEscapedReservedCharactersInTheValue() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .equipmentProperty,
      fields: ["R", "AI", "503123450", 101, "a^2Cb"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .equipmentProperty(type, _, _, value) = payload else {
      Issue.record("expected .equipmentProperty, got \(payload)")
      return
    }

    #expect(type == .reply)
    #expect(value == "a,b")
  }

  @Test("throws when the property identifier is negative")
  func throwsWhenThePropertyIdentifierIsNegative() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .ECDIS,
      format: .equipmentProperty,
      fields: ["C", "AI", "503123450", -1, "38400"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
  }
}
