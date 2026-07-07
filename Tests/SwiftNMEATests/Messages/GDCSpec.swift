import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.39 GDC")
struct GDCTests {
  // MARK: - .parse

  @Test("parses a single-sentence message")
  func parsesASingleSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSDifferentialCorrection,
      fields: [
        1, 1, 1,
        12, -1.5, 42, 432_000, 1234.5, 7.25, 5
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .GNSSDifferentialCorrection(corrections, totalSatellites) = payload else {
      Issue.record("expected .GNSSDifferentialCorrection, got \(payload)")
      return
    }

    #expect(totalSatellites == 1)
    #expect(corrections.count == 1)

    let correction = corrections[0]
    guard case let .GPS(id, signal) = correction.satellite else {
      Issue.record("expected .GPS, got \(correction.satellite)")
      return
    }
    #expect(id == 12)
    #expect(signal == .L2C_M)
    #expect(correction.pseudorangeCorrection == .init(value: -1.5, unit: .meters))
    #expect(correction.issueOfData == 42)
    #expect(correction.epochTime == .init(value: 432_000, unit: .seconds))
    #expect(correction.modifiedZCount == .init(value: 1234.5, unit: .seconds))
    #expect(correction.UDRE == .init(value: 7.25, unit: .meters))
  }

  @Test("accumulates corrections across multiple sentences")
  func accumulatesCorrectionsAcrossMultipleSentences() async throws {
    let parser = SwiftNMEA()
    let first = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSDifferentialCorrection,
      fields: [2, 1, 2, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
    )
    let second = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSDifferentialCorrection,
      fields: [2, 2, 2, 17, 2.5, 43, 432_006, 1240.0, 3.0, 1]
    )
    let data = (first + second).data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // sentence echo + sentence echo + completed message
    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    guard case let .GNSSDifferentialCorrection(corrections, totalSatellites) = payload else {
      Issue.record("expected .GNSSDifferentialCorrection, got \(payload)")
      return
    }

    #expect(totalSatellites == 2)
    #expect(corrections.count == 2)
    let ids = corrections.compactMap { correction -> Int? in
      guard case let .GPS(id, _) = correction.satellite else { return nil }
      return id
    }
    #expect(ids.contains(12) && ids.contains(17))
  }

  @Test("throws an error for an invalid signal ID")
  func throwsAnErrorForAnInvalidSignalID() async throws {
    let parser = SwiftNMEA()
    // GPS signal IDs only range 0–8; 9 is reserved/invalid.
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSDifferentialCorrection,
      fields: [1, 1, 1, 12, -1.5, 42, 432_000, 1234.5, 7.25, 9]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
    #expect(error.fieldNumber == 9)
  }

  @Test("throws an error for the disallowed combined-GNSS talker")
  func throwsAnErrorForTheDisallowedCombinedGNSSTalker() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .GNSSDifferentialCorrection,
      fields: [1, 1, 1, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownTalker)
  }

  // MARK: - .flush

  @Test("flushes incomplete messages")
  func flushesIncompleteMessages() async throws {
    let parser = SwiftNMEA()
    let first = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSDifferentialCorrection,
      fields: [2, 1, 2, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
    )
    let data = first.data(using: .ascii)!
    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    let payload = try #require((flushed[0] as? Message)?.payload)
    guard case let .GNSSDifferentialCorrection(corrections, _) = payload else {
      Issue.record("expected .GNSSDifferentialCorrection, got \(payload)")
      return
    }
    #expect(corrections.count == 1)
  }
}
