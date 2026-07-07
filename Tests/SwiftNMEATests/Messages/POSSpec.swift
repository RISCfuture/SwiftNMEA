import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.76 POS")
struct POSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .positionDimensions,
      fields: [
        "AG", "00",
        "A", 1.2, 3.4, 5.6,
        "V", 7.8, 9.9,
        "R"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .positionDimensions(
        equipment,
        equipmentNumber,
        positionValid,
        position,
        dimensionsValid,
        dimensions,
        status
      ) = payload
    else {
      Issue.record("expected .positionDimensions, got \(payload)")
      return
    }

    #expect(equipment == .autopilotGeneral)
    #expect(equipmentNumber == 0)
    #expect(positionValid)
    #expect(position.x == .init(value: 1.2, unit: .meters))
    #expect(position.y == .init(value: 3.4, unit: .meters))
    #expect(position.z == .init(value: 5.6, unit: .meters))
    #expect(!dimensionsValid)
    #expect(dimensions.width == .init(value: 7.8, unit: .meters))
    #expect(dimensions.length == .init(value: 9.9, unit: .meters))
    #expect(status == .reply)
  }
}
