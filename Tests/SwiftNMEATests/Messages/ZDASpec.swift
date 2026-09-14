import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.130 ZDA` {
  @Test(arguments: SpecExample.all)
  func `parses an example from the spec (corrected)`(_ example: SpecExample) async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: example.sentence)
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .dateTime(date, timeZone) = payload else {
      Issue.record("expected .dateTime, got \(payload)")
      return
    }

    #expect(date == example.expectedDate)
    #expect(timeZone == example.timeZone)
  }

  /// One of the `ZDA` examples from §8.3.130 of the spec, with the local-time
  /// arithmetic corrected.
  struct SpecExample: Sendable, CustomTestStringConvertible {
    /// Chatham Island Time, UTC+12:45.
    private static let CHAT = TimeZone(secondsFromGMT: 12 * 60 * 60 + 45 * 60)!

    /// UTC−10:30.
    private static let KCT = TimeZone(secondsFromGMT: -10 * 60 * 60 - 30 * 60)!

    static let all: [Self] = [
      .init(
        ordinal: "first",
        sentence: "$GPZDA,234500.00,09,06,1995,-12,45",
        timeZone: CHAT,
        localComponents: components(in: CHAT, day: 10, hour: 12, minute: 30)
      ),
      .init(
        ordinal: "second",
        sentence: "$GPZDA,013000.00,11,06,1995,10,30",
        timeZone: KCT,
        localComponents: components(in: KCT, day: 10, hour: 15, minute: 0)
      )
    ]

    let ordinal: String
    let sentence: String
    let timeZone: TimeZone
    let localComponents: DateComponents

    var expectedDate: Date {
      Calendar.current.date(from: localComponents)!
    }

    var testDescription: String { "\(ordinal) example: \(sentence)" }

    private static func components(
      in timeZone: TimeZone,
      day: Int,
      hour: Int,
      minute: Int
    ) -> DateComponents {
      .init(timeZone: timeZone, year: 1995, month: 6, day: day, hour: hour, minute: minute)
    }
  }
}
