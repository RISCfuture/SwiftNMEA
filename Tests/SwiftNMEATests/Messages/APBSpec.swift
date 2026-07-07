import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.16 APB")
struct APBTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .autopilotSentenceB,
      fields: [
        "A", "V",
        12.3, "L", "N",
        "V", "A",
        101.0, "T",
        "KOAK",
        123.0, "T",
        5.5, "M",
        "D"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .autopilotSentenceB(
        LORANC_blinkSNRFlag,
        LORANC_cycleLockWarningFlag,
        crossTrackError,
        arrivalCircleEntered,
        perpendicularPassed,
        bearingOriginToDest,
        destinationID,
        bearingPresentPosToDest,
        headingToDest,
        mode
      ) = payload
    else {
      Issue.record("expected .autopilotSentenceB, got \(payload)")
      return
    }

    #expect(LORANC_blinkSNRFlag == false)
    #expect(LORANC_cycleLockWarningFlag == true)
    #expect(crossTrackError == .init(value: -12.3, unit: .nauticalMiles))
    #expect(arrivalCircleEntered == false)
    #expect(perpendicularPassed == true)
    #expect(bearingOriginToDest == .init(degrees: 101.0, reference: .true))
    #expect(destinationID == "KOAK")
    #expect(bearingPresentPosToDest == .init(degrees: 123.0, reference: .true))
    #expect(headingToDest == .init(degrees: 5.5, reference: .magnetic))
    #expect(mode == .differential)
  }
}
