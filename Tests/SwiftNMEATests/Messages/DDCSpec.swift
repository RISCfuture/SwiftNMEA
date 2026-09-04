import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.26 DDC` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .displayDimmingControl,
      fields: ["K", 50, "D", "R", "O"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .displayDimmingControl(
          preset: .dusk,
          brightness: 50,
          colorPalette: .day,
          status: .reply,
          commandMode: .operational
        )
    )
  }

  @Test
  func `throws when the command mode is missing`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .displayDimmingControl,
      fields: ["K", 50, "D", "R", nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .missingRequiredValue)
  }
}
