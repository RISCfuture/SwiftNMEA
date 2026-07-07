import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.54 HMS")
struct HMSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .headingMonitorSet,
      fields: ["HDG1", "HDG2", 5.0]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .headingMonitorSet(sensor1, sensor2, maxDiff) = payload else {
      Issue.record("expected .headingMonitorSet, got \(payload)")
      return
    }

    #expect(sensor1 == "HDG1")
    #expect(sensor2 == "HDG2")
    #expect(maxDiff == .init(value: 5.0, unit: .degrees))
  }
}
