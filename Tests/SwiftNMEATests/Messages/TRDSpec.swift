import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.105 TRD")
struct TRDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .propulsion,
      format: .thrusterResponse,
      fields: [1, 12.3, "P", 23.4, "D", 123.4, "B", "R"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .thrusterResponse(number, RPM, pitch, azimuth) = payload else {
      Issue.record("expected .thrusterResponse, got \(payload)")
      return
    }

    #expect(number == 1)
    #expect(RPM == .percent(12.3))
    #expect(pitch == .value(.init(value: 23.4, unit: .degrees)))
    #expect(azimuth == .init(value: 123.4, unit: .degrees))
  }
}
