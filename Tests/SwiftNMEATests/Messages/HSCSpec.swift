import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.56 HSC")
struct HSCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .headingSteeringCommand,
      fields: [12.3, "T", 23.4, "M", "C"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .headingSteeringCommand(headingTrue, headingMagnetic, status) = payload
    else {
      Issue.record("expected .headingSteeringCommand, got \(payload)")
      return
    }

    #expect(headingTrue.angle == .init(value: 12.3, unit: .degrees))
    #expect(headingTrue.reference == .true)
    #expect(headingMagnetic.angle == .init(value: 23.4, unit: .degrees))
    #expect(headingMagnetic.reference == .magnetic)
    #expect(status == .command)
  }
}
