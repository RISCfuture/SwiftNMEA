import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.119 VLW")
struct VLWTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .distanceData,
      fields: [123.4, "N", 12.3, "N", 124.5, "N", 12.4, "N"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .distanceData(
        waterCumulative,
        waterSinceReset,
        groundCumulative,
        groundSinceReset
      ) =
        payload
    else {
      Issue.record("expected .distanceData, got \(payload)")
      return
    }

    #expect(waterCumulative == .init(value: 123.4, unit: .nauticalMiles))
    #expect(waterSinceReset == .init(value: 12.3, unit: .nauticalMiles))
    #expect(groundCumulative == .init(value: 124.5, unit: .nauticalMiles))
    #expect(groundSinceReset == .init(value: 12.4, unit: .nauticalMiles))
  }
}
