import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.47 GST")
struct GSTTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -12)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .GNSSPseudorangeNoise,
      fields: [
        hmsFractionFormatter.string(from: time),
        1.1, 2.2, 3.3, 4.4,
        5.5, 6.6, 7.7
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSSPseudorangeNoise(
        actualTime,
        rangeStddevRMS,
        errorSemimajorStddev,
        errorSemiminorStddev,
        errorOrientation,
        errorLatitudeStddev,
        errorLongitudeStddev,
        errorAltitudeStddev
      ) = payload
    else {
      Issue.record("expected .GNSSPseudorangeNoise, got \(payload)")
      return
    }

    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(rangeStddevRMS == 1.1)
    #expect(errorSemimajorStddev == .init(value: 2.2, unit: .meters))
    #expect(errorSemiminorStddev == .init(value: 3.3, unit: .meters))
    #expect(errorOrientation == .init(angle: .init(value: 4.4, unit: .degrees), reference: .true))
    #expect(errorLatitudeStddev == .init(value: 5.5, unit: .meters))
    #expect(errorLongitudeStddev == .init(value: 6.6, unit: .meters))
    #expect(errorAltitudeStddev == .init(value: 7.7, unit: .meters))
  }
}
