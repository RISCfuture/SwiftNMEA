import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.82 ROR")
struct RORTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .rudderOrder,
      fields: [1.2, "A", -2.3, "V", "W", 3.4, "A", -4.5, "V"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .rudderOrder(
        starboard,
        port,
        starboardValid,
        portValid,
        commandSource,
        center,
        centerValid,
        bow,
        bowValid
      ) = payload
    else {
      Issue.record("expected .rudderOrder, got \(payload)")
      return
    }

    #expect(starboard == 1.2)
    #expect(starboardValid)
    #expect(port == -2.3)
    #expect(portValid == false)
    #expect(commandSource == .wing)
    #expect(center == 3.4)
    #expect(centerValid == true)
    #expect(bow == -4.5)
    #expect(bowValid == false)
  }

  @Test("throws when a rudder order has no corresponding status")
  func throwsWhenARudderOrderHasNoCorrespondingStatus() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .rudderOrder,
      fields: [1.2, "A", -2.3, "V", "W", 3.4, nil, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 6)
  }
}
