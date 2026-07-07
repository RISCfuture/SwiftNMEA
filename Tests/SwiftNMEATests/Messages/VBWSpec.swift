import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.113 VBW")
struct VBWTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .speedData,
      fields: [
        12.3, 1.2, "A",
        23.4, 2.3, "V",
        3.4, "A",
        5.6, "V"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    guard
      case let .speedData(
        water,
        waterValid,
        ground,
        groundValid,
        sternTransverseWater,
        sternTransverseWaterValid,
        sternTransverseGround,
        sternTransverseGroundValid
      ) = payload
    else {
      Issue.record("expected .speedData, got \(payload)")
      return
    }

    #expect(water.longitudinal == .init(value: 12.3, unit: .knots))
    #expect(water.transverse == .init(value: 1.2, unit: .knots))
    #expect(waterValid)
    #expect(ground.longitudinal == .init(value: 23.4, unit: .knots))
    #expect(ground.transverse == .init(value: 2.3, unit: .knots))
    #expect(!groundValid)
    #expect(sternTransverseWater == .init(value: 3.4, unit: .knots))
    #expect(sternTransverseWaterValid)
    #expect(sternTransverseGround == .init(value: 5.6, unit: .knots))
    #expect(!sternTransverseGroundValid)
  }
}
