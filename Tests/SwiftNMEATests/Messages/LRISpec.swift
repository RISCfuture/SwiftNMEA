import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.63 LRI and friends")
struct LRITests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let LRI = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeInterrogation,
      fields: [
        1, 0, 1_234_567_890, nil,
        "3530.00", "N", "12115.00", "W",
        "3400.00", "N", "12030.00", "W"
      ]
    )
    let LRF = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeFunction,
      fields: [
        1, 1_234_567_890, "HAIL MARY",
        "ABCEFIOPW", nil
      ]
    )
    let data = LRI.data(using: .ascii)! + LRF.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    guard
      case let .AISLongRangeInterrogation(
        replyLogic,
        requestorMMSI,
        requestorName,
        destination,
        functions
      ) =
        payload
    else {
      Issue.record("expected .AISLongRangeInterrogation, got \(payload)")
      return
    }

    #expect(replyLogic == .normal)
    #expect(requestorMMSI == 1_234_567_890)
    #expect(requestorName == "HAIL MARY")
    #expect(
      destination
        == .area(
          .init(
            northeast: .init(latitude: 35.5, longitude: -121.25),
            southwest: .init(latitude: 34.0, longitude: -120.5)
          )
        )
    )
    #expect(
      functions
        == .init([
          .shipID,
          .dateTime,
          .position,
          .course,
          .speed,
          .destination,
          .draught,
          .cargo,
          .soulsOnboard
        ])
    )
  }

  @Test("throws an error if a duplicate sentence is received")
  func throwsAnErrorIfADuplicateSentenceIsReceived() async throws {
    let parser = SwiftNMEA()
    let LRI = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeInterrogation,
      fields: [
        1, 0, 1_234_567_890, nil,
        "3530.00", "N", "12115.00", "W",
        "3400.00", "N", "12030.00", "W"
      ]
    )
    let LRI2 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeInterrogation,
      fields: [
        1, 0, 1_234_567_890, nil,
        "3530.00", "N", "12115.00", "W",
        "3400.00", "N", "12030.00", "W"
      ]
    )
    let data = LRI.data(using: .ascii)! + LRI2.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .unexpectedFormat)
  }
}
