import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.118 VHW")
struct VHWTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .waterSpeedHeading,
      fields: [123.4, "T", 124.5, "M", 12.3, "N", 23.4, "K"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .waterSpeedHeading(bearingTrue, magnetic, speedKnots, speedKph) =
        payload
    else {
      Issue.record("expected .waterSpeedHeading, got \(payload)")
      return
    }

    #expect(bearingTrue.angle == .init(value: 123.4, unit: .degrees))
    #expect(bearingTrue.reference == .true)
    #expect(magnetic.angle == .init(value: 124.5, unit: .degrees))
    #expect(magnetic.reference == .magnetic)
    #expect(speedKnots == .init(value: 12.3, unit: .knots))
    #expect(speedKph == .init(value: 23.4, unit: .kilometersPerHour))
  }
}
