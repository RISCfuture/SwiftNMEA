import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.62 LRF and friends")
struct LRFTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let fixTime = Date(timeIntervalSinceNow: -5)
    let ETA = Date(timeIntervalSinceNow: 60000)
    let LRF = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeFunction,
      fields: [
        1, 1_234_567_890, "MORIARTY",
        "ABCEFIOPUW", "22222222222"
      ]
    )
    let LR1 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply1,
      fields: [
        1, 1_234_567_890,
        9_876_543_210, "HAIL MARY", "HAIL^5EMRY", 1_029_384_756
      ]
    )
    let LR2 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply2,
      fields: [
        1, 1_234_567_890,
        dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
        "3530.00", "N", "12115.00", "W",
        "225.5", "T",
        "12.3", "N"
      ]
    )
    let LR3 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply3,
      fields: [
        1, 1_234_567_890,
        "OAKLAND",
        dateFormatter.string(from: ETA), hmsFractionFormatter.string(from: ETA),
        1.2, 31, 34.5, 12.3, 81, 123
      ]
    )
    let data =
      LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)!
      + LR3.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    let payload = try #require((messages[4] as? Message)?.payload)
    guard
      case let .AISLongRangeReply(
        requestorMMSI,
        requestorName,
        replyStatuses,
        actualFixTime,
        shipName,
        shipCallsign,
        shipIMO,
        position,
        course,
        speed,
        destination,
        actualETA,
        shipType,
        shipType2,
        length,
        breadth,
        draught,
        soulsOnboard
      ) = payload
    else {
      Issue.record("expected .AISLongRangeReply, got \(payload)")
      return
    }

    #expect(requestorMMSI == 1_234_567_890)
    #expect(requestorName == "MORIARTY")
    #expect(
      replyStatuses == [
        .shipID: .available,
        .dateTime: .available,
        .position: .available,
        .course: .available,
        .speed: .available,
        .destination: .available,
        .draught: .available,
        .cargo: .available,
        .shipDimensions: .available,
        .soulsOnboard: .available
      ]
    )
    #expect(shipName == "HAIL MARY")
    #expect(shipCallsign == "HAIL^MRY")
    #expect(shipIMO == 1_029_384_756)

    #expect(abs(actualFixTime!.timeIntervalSince(fixTime)) < 0.01)
    #expect(position!.latitude == .init(value: 35.5, unit: .degrees))
    #expect(position!.longitude == .init(value: -121.25, unit: .degrees))
    #expect(course!.angle == .init(value: 225.5, unit: .degrees))
    #expect(course!.reference == .true)
    #expect(speed == .init(value: 12.3, unit: .knots))

    #expect(destination == "OAKLAND")
    #expect(abs(actualETA!.timeIntervalSince(ETA)) < 0.01)
    #expect(draught == .init(value: 1.2, unit: .meters))
    #expect(shipType == .vessel(operation: .towing))
    #expect(length == .init(value: 34.5, unit: .meters))
    #expect(breadth == .init(value: 12.3, unit: .meters))
    #expect(shipType2 == .tanker(.categoryX))
    #expect(soulsOnboard == 123)
  }

  @Test("throws an error if a duplicate sentence is received")
  func throwsAnErrorIfADuplicateSentenceIsReceived() async throws {
    let parser = SwiftNMEA()
    let fixTime = Date(timeIntervalSinceNow: -5)
    let LRF = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeFunction,
      fields: [
        1, 1_234_567_890, "MORIARTY",
        "ABCEFIOPUW", "22222222222"
      ]
    )
    let LR1 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply1,
      fields: [
        1, 1_234_567_890,
        9_876_543_210, "HAIL MARY", "HAILMRY", 1_029_384_756
      ]
    )
    let LR2 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply2,
      fields: [
        1, 1_234_567_890,
        dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
        "3530.00", "N", "12115.00", "W",
        "225.5", "T",
        "12.3", "N"
      ]
    )
    let  // oops! another LR2
    LR2_2 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply2,
      fields: [
        1, 1_234_567_890,
        dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
        "3530.00", "N", "12115.00", "W",
        "225.5", "T",
        "12.3", "N"
      ]
    )
    let data =
      LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)!
      + LR2_2.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)
    guard let error = messages[4] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[4])")
      return
    }
    #expect(error.type == .unexpectedFormat)
  }

  @Test("throws an error if an unexpected sentence is received")
  func throwsAnErrorIfAnUnexpectedSentenceIsReceived() async throws {
    let parser = SwiftNMEA()
    let ETA = Date(timeIntervalSinceNow: 60000)
    let LRF = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeFunction,
      fields: [
        1, 1_234_567_890, "MORIARTY",
        "ABCEF", "22222222222"
      ]
    )
    let LR1 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply1,
      fields: [
        1, 1_234_567_890,
        9_876_543_210, "HAIL MARY", "HAILMRY", 1_029_384_756
      ]
    )
    let  // oops! unexpected LR3
    LR3 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply3,
      fields: [
        1, 1_234_567_890,
        "OAKLAND",
        dateFormatter.string(from: ETA), hmsFractionFormatter.string(from: ETA),
        1.2, 31, 34.5, 12.3, 81, 123
      ]
    )
    let data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR3.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 4)
    guard let error = messages[3] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[3])")
      return
    }
    #expect(error.type == .unexpectedFormat)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let fixTime = Date(timeIntervalSinceNow: -5)
    let LRF = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeFunction,
      fields: [
        1, 1_234_567_890, "MORIARTY",
        "ABCEFIOPUW", "22222222222"
      ]
    )
    let LR1 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply1,
      fields: [
        1, 1_234_567_890,
        9_876_543_210, "HAIL MARY", "HAILMRY", 1_029_384_756
      ]
    )
    let LR2 = createSentence(
      delimiter: .parametric,
      talker: .commVHF,
      format: .AISLongRangeReply2,
      fields: [
        1, 1_234_567_890,
        dateFormatter.string(from: fixTime), hmsFractionFormatter.string(from: fixTime),
        "3530.00", "N", "12115.00", "W",
        "225.5", "T",
        "12.3", "N"
      ]
    )
    let data = LRF.data(using: .ascii)! + LR1.data(using: .ascii)! + LR2.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 3)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    guard let message = messages[0] as? Message else {
      Issue.record("expected Message, got \(messages[0])")
      return
    }
    guard
      case let .AISLongRangeReply(
        requestorMMSI,
        requestorName,
        replyStatuses,
        actualFixTime,
        shipName,
        shipCallsign,
        shipIMO,
        position,
        course,
        speed,
        destination,
        actualETA,
        shipType,
        shipType2,
        length,
        breadth,
        draught,
        soulsOnboard
      ) = message.payload
    else {
      Issue.record("expected .AISLongRangeReply, got \(message)")
      return
    }

    #expect(requestorMMSI == 1_234_567_890)
    #expect(requestorName == "MORIARTY")
    #expect(
      replyStatuses == [
        .shipID: .available,
        .dateTime: .available,
        .position: .available,
        .course: .available,
        .speed: .available,
        .destination: .available,
        .draught: .available,
        .cargo: .available,
        .shipDimensions: .available,
        .soulsOnboard: .available
      ]
    )
    #expect(shipName == "HAIL MARY")
    #expect(shipCallsign == "HAILMRY")
    #expect(shipIMO == 1_029_384_756)

    #expect(abs(actualFixTime!.timeIntervalSince(fixTime)) < 0.01)
    #expect(position!.latitude == .init(value: 35.5, unit: .degrees))
    #expect(position!.longitude == .init(value: -121.25, unit: .degrees))
    #expect(course!.angle == .init(value: 225.5, unit: .degrees))
    #expect(course!.reference == .true)
    #expect(speed == .init(value: 12.3, unit: .knots))

    #expect(destination == nil)
    #expect(actualETA == nil)
    #expect(draught == nil)
    #expect(shipType == nil)
    #expect(length == nil)
    #expect(breadth == nil)
    #expect(shipType2 == nil)
    #expect(soulsOnboard == nil)
  }
}
