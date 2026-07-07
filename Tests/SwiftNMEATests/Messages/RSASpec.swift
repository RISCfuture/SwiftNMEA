import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.86 RSA")
struct RSATests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .rudderSensorAngle,
      fields: [1.2, "A", -2.3, "V", 3.4, "A", -4.5, "V"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .rudderSensorAngle(
        starboard,
        port,
        starboardValid,
        portValid,
        center,
        centerValid,
        bowOrOther,
        bowOrOtherValid
      ) = payload
    else {
      Issue.record("expected .rudderSensorAngle, got \(payload)")
      return
    }

    #expect(starboard == 1.2)
    #expect(starboardValid == true)
    #expect(port == -2.3)
    #expect(portValid == false)
    #expect(center == 3.4)
    #expect(centerValid == true)
    #expect(bowOrOther == -4.5)
    #expect(bowOrOtherValid == false)
  }

  @Test("throws when a rudder sensor has no corresponding status")
  func throwsWhenARudderSensorHasNoCorrespondingStatus() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .steering,
      format: .rudderSensorAngle,
      fields: [1.2, nil, -2.3, "V", nil, nil, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 1)
  }
}
