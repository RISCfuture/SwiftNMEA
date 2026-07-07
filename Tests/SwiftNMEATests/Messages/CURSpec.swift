import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.24 CUR")
struct CURTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .depthSounder,
      format: .currentWaterLayer,
      fields: [
        "A", 2, 3,
        3.5,
        120.5, "R",
        11.2,
        2.0,
        99.3, "T",
        "B"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .currentWaterLayer(
        isValid,
        setNumber,
        layer,
        depth,
        direction,
        speed,
        referenceDepth,
        heading,
        speedReference
      ) = payload
    else {
      Issue.record("expected .currentWaterLayer, got \(payload)")
      return
    }

    #expect(isValid)
    #expect(setNumber == 2)
    #expect(layer == 3)
    #expect(depth == .init(value: 3.5, unit: .meters))
    #expect(direction == .init(degrees: 120.5, reference: .relative))
    #expect(speed == .init(value: 11.2, unit: .knots))
    #expect(referenceDepth == .init(value: 2.0, unit: .meters))
    #expect(heading == .init(degrees: 99.3, reference: .true))
    #expect(speedReference == .bottomTrack)
  }
}
