import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.98 SPW")
struct SPWTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .securityPassword,
      fields: ["EPV", "211000001", 2, "SESAME"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .securityPassword(protectedSentence, uniqueID, level, password) = payload
    else {
      Issue.record("expected .securityPassword, got \(payload)")
      return
    }

    #expect(protectedSentence == .unknown("EPV"))
    #expect(uniqueID == "211000001")
    #expect(level == .administrator)
    #expect(password == "SESAME")
  }

  @Test("throws an error for a reserved password level")
  func throwsAnErrorForAReservedPasswordLevel() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .securityPassword,
      fields: ["EPV", "211000001", 5, "SESAME"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .unknownValue)
  }
}
