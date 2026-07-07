import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.68 MWD")
struct MWDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commDataReceiver,
      format: .windDirectionSpeed,
      fields: [
        225.0, "T", 220.0, "M",
        12.5, "N", 6.43, "M"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .windDirectionSpeed(
        directionTrue,
        directionMagnetic,
        speedKnots,
        speedMps
      ) = payload
    else {
      Issue.record("expected .windDirectionSpeed, got \(payload)")
      return
    }

    #expect(directionTrue.angle == .init(value: 225.0, unit: .degrees))
    #expect(directionTrue.reference == .true)
    #expect(directionMagnetic.angle == .init(value: 220.0, unit: .degrees))
    #expect(directionMagnetic.reference == .magnetic)
    #expect(speedKnots == .init(value: 12.5, unit: .knots))
    #expect(speedMps == .init(value: 6.43, unit: .metersPerSecond))
  }
}
