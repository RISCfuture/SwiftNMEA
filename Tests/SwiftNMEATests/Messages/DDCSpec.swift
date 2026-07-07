import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.26 DDC")
struct DDCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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

  @Test("throws when the command mode is missing")
  func throwsWhenTheCommandModeIsMissing() async throws {
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
