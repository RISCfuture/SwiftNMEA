import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.91 SLM` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .steeringLocationMode,
      fields: [1, "O", "Bow thruster panel", "P", "DP Main"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .steeringLocationMode(
          systemStatus: .active,
          location: .others,
          locationDescription: "Bow thruster panel",
          mode: .dynamicPositioning,
          subMode: "DP Main"
        )
    )
  }

  @Test
  func `parses a sentence with unavailable optional values`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .steeringLocationMode,
      fields: [0, "B", nil, "M", nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .steeringLocationMode(
          systemStatus: .passive,
          location: .bridge,
          locationDescription: nil,
          mode: .manual,
          subMode: nil
        )
    )
  }

  @Test
  func `throws an error for an unknown system status`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .steeringLocationMode,
      fields: [5, "B", nil, "M", nil]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }

  @Test
  func `throws an error when location is Others but description is missing`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .steeringLocationMode,
      fields: [1, "O", nil, "P", nil]
    )
    let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
  }
}
