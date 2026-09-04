import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.120 VPW` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .speedParallelToWind,
      fields: [12.3, "N", 23.4, "M"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .speedParallelToWind(knots, mps) = payload else {
      Issue.record("expected .speedMadeGood, got \(payload)")
      return
    }

    #expect(knots == .init(value: 12.3, unit: .knots))
    #expect(mps == .init(value: 23.4, unit: .metersPerSecond))
  }
}
