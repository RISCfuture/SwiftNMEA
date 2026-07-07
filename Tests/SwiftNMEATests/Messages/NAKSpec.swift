import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.70 NAK")
struct NAKTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commDataReceiver,
      format: .negativeAcknowledgement,
      fields: ["SG", "HSC", nil, 10, "DISCONNECTED"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .negativeAcknowledgement(
        talker,
        format,
        uniqueID,
        reasonCode,
        reason
      ) = payload
    else {
      Issue.record("expected .negativeAcknowledgement, got \(payload)")
      return
    }

    #expect(talker == .steering)
    #expect(format == .headingSteeringCommand)
    #expect(uniqueID == nil)
    #expect(reasonCode == .unable)
    #expect(reason == "DISCONNECTED")
  }
}
