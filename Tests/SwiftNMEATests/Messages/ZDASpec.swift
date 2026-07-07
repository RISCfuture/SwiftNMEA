import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.130 ZDA")
struct ZDATests {
  @Test("parses the first example from the spec (corrected)")
  func parsesTheFirstExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$GPZDA,234500.00,09,06,1995,-12,45")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .dateTime(date, timeZone) = payload else {
      Issue.record("expected .dateTime, got \(payload)")
      return
    }

    let CHAT = TimeZone(secondsFromGMT: 12 * 60 * 60 + 45 * 60)!
    let expectedDateComponents = DateComponents(
      timeZone: CHAT,
      year: 1995,
      month: 6,
      day: 10,
      hour: 12,
      minute: 30
    )
    let expectedDate = Calendar.current.date(from: expectedDateComponents)!

    #expect(date == expectedDate)
    #expect(timeZone == CHAT)
  }

  @Test("parses the second example from the spec (corrected)")
  func parsesTheSecondExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$GPZDA,013000.00,11,06,1995,10,30")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .dateTime(date, timeZone) = payload else {
      Issue.record("expected .dateTime, got \(payload)")
      return
    }

    let KCT = TimeZone(secondsFromGMT: -10 * 60 * 60 - 30 * 60)!
    let expectedDateComponents = DateComponents(
      timeZone: KCT,
      year: 1995,
      month: 6,
      day: 10,
      hour: 15,
      minute: 0
    )
    let expectedDate = Calendar.current.date(from: expectedDateComponents)!

    #expect(date == expectedDate)
    #expect(timeZone == KCT)
  }
}
