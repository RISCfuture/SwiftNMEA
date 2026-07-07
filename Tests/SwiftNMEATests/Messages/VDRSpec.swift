import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.116 VDR")
struct VDRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .currentSetDrift,
      fields: [123.4, "T", 124.5, "M", 12.3, "N"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .currentSetDrift(setTrue, setMagnetic, drift) = payload else {
      Issue.record("expected .currentSetDrift, got \(payload)")
      return
    }

    #expect(setTrue.angle == .init(value: 123.4, unit: .degrees))
    #expect(setTrue.reference == .true)
    #expect(setMagnetic.angle == .init(value: 124.5, unit: .degrees))
    #expect(setMagnetic.reference == .magnetic)
    #expect(drift == .init(value: 12.3, unit: .knots))
  }
}
