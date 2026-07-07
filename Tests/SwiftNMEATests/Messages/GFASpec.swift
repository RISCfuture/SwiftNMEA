import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.41 GFA")
struct GFATests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -23)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .GNSSAccuracyIntegrity,
      fields: [
        hmsFractionFormatter.string(from: time),
        1.2, 3.4, 0.5, 0.75, 12.3, 0.6, 5.0, "VSC"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .GNSSAccuracyIntegrity(
        actualTime,
        HPL,
        VPL,
        semimajorStddev,
        semiminorStddev,
        semimajorErrorOrientation,
        altitudeStddev,
        selectedAccuracy,
        integrity
      ) =
        payload
    else {
      Issue.record("expected .GNSSAccuracyIntegrity, got \(payload)")
      return
    }

    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(HPL == .init(value: 1.2, unit: .meters))
    #expect(VPL == .init(value: 3.4, unit: .meters))
    #expect(semimajorStddev == .init(value: 0.5, unit: .meters))
    #expect(semiminorStddev == .init(value: 0.75, unit: .meters))
    #expect(semimajorErrorOrientation.angle == .init(value: 12.3, unit: .degrees))
    #expect(semimajorErrorOrientation.reference == .true)
    #expect(altitudeStddev == .init(value: 0.6, unit: .meters))
    #expect(selectedAccuracy == .init(value: 5.0, unit: .meters))
    #expect(integrity == [.RAIM: .notInUse, .SBAS: .safe, .GIC: .caution])
  }
}
