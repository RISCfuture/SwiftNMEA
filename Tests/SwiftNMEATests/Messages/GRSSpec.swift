import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.45 GRS")
struct GRSTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -2)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSRangeResiduals,
      fields: [
        hmsFractionFormatter.string(from: time), 0,
        0.1, 0.2, 0.3, 0.4, 0.5,
        1, 7
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .GNSSRangeResiduals(residuals, actualTime, recomputed) = payload
    else {
      Issue.record("expected .GNSSRangeResiduals, got \(payload)")
      return
    }

    #expect(
      residuals == [
        .GPS(0, signal: .L5_I): .init(value: 0.1, unit: .meters),
        .GPS(1, signal: .L5_I): .init(value: 0.2, unit: .meters),
        .GPS(2, signal: .L5_I): .init(value: 0.3, unit: .meters),
        .GPS(3, signal: .L5_I): .init(value: 0.4, unit: .meters),
        .GPS(4, signal: .L5_I): .init(value: 0.5, unit: .meters)
      ]
    )
    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(!recomputed)
  }

  @Test("returns an error for a too-short sentence instead of crashing")
  func returnsAnErrorForATooShortSentenceInsteadOfCrashing() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -2)
    // Only the time/mode header plus the trailing System ID / Signal ID:
    // there are no residual fields, so required values are missing.
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSRangeResiduals,
      fields: [hmsFractionFormatter.string(from: time), 0, 7]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .missingRequiredValue)
  }
}
