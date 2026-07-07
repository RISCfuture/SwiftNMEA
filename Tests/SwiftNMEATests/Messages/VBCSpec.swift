import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.112 VBC")
struct VBCTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dockingSpeedData,
      fields: [
        12.3, 1.1, -1.2, 0.5, "A",
        23.4, 2.1, -2.2, 1.5, "V"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    guard
      case let .dockingSpeedData(water, waterValid, ground, groundValid) = payload
    else {
      Issue.record("expected .dockingSpeedData, got \(payload)")
      return
    }

    #expect(water.longitudinal == .init(value: 12.3, unit: .knots))
    #expect(water.bowTransverse == .init(value: 1.1, unit: .knots))
    #expect(water.transverse == .init(value: -1.2, unit: .knots))
    #expect(water.sternTransverse == .init(value: 0.5, unit: .knots))
    #expect(waterValid)
    #expect(ground.longitudinal == .init(value: 23.4, unit: .knots))
    #expect(ground.bowTransverse == .init(value: 2.1, unit: .knots))
    #expect(ground.transverse == .init(value: -2.2, unit: .knots))
    #expect(ground.sternTransverse == .init(value: 1.5, unit: .knots))
    #expect(!groundValid)
  }

  @Test("throws an error when the water-speed status is a null field")
  func throwsAnErrorWhenTheWaterSpeedStatusIsANullField() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dockingSpeedData,
      fields: [
        12.3, 1.1, -1.2, 0.5, "",
        23.4, 2.1, -2.2, 1.5, "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
  }

  @Test("throws an error for a non-numeric speed")
  func throwsAnErrorForANonNumericSpeed()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dockingSpeedData,
      fields: [
        "bogus", 1.1, -1.2, 0.5, "A",
        23.4, 2.1, -2.2, 1.5, "V"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
  }
}
