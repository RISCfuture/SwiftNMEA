import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.106 TRL")
struct TRLTests {
  @Test("parses a single log entry")
  func parsesASingleLogEntry() async throws {
    let parser = SwiftNMEA()
    // total=1, entry=1, sequentialID=3, switch off 15 May 2025 08:15:00,
    // switch on 15 May 2025 09:30:00, reason = power off
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISTransmitterNonFunctioningLog,
      fields: [1, 1, 3, "15052025", "081500.00", "15052025", "093000.00", 1]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
      Issue.record("expected .AISTransmitterNonFunctioningLog, got \(payload)")
      return
    }

    #expect(id == 3)
    #expect(entries.count == 1)

    let entry = entries[0]
    #expect(entry.number == 1)
    #expect(entry.reason == .powerOff)

    let switchOff = Calendar.current.date(
      from: DateComponents(
        timeZone: .gmt,
        year: 2025,
        month: 5,
        day: 15,
        hour: 8,
        minute: 15,
        second: 0
      )
    )
    let switchOn = Calendar.current.date(
      from: DateComponents(
        timeZone: .gmt,
        year: 2025,
        month: 5,
        day: 15,
        hour: 9,
        minute: 30,
        second: 0
      )
    )
    #expect(entry.switchOff == switchOff)
    #expect(entry.switchOn == switchOn)
  }

  @Test("assembles a multi-entry log")
  func assemblesAMultiEntryLog() async throws {
    let parser = SwiftNMEA()
    let first = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISTransmitterNonFunctioningLog,
      fields: [2, 1, 4, "15052025", "081500.00", "15052025", "093000.00", 1]
    )
    let second = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISTransmitterNonFunctioningLog,
      fields: [2, 2, 4, "16052025", "100000.00", "16052025", "120000.00", 4]
    )
    let data = (first + second).data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // the assembled log is emitted on receipt of the last entry
    let lastPayload = messages.compactMap { ($0 as? Message)?.payload }.last
    let payload = try #require(lastPayload)
    guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
      Issue.record("expected .AISTransmitterNonFunctioningLog, got \(payload)")
      return
    }

    #expect(id == 4)
    #expect(entries.count == 2)
    #expect(entries[0].number == 1)
    #expect(entries[0].reason == .powerOff)
    #expect(entries[1].number == 2)
    #expect(entries[1].reason == .equipmentMalfunction)
  }

  @Test("parses an empty log with null fields")
  func parsesAnEmptyLogWithNullFields()
    async throws
  {
    let parser = SwiftNMEA()
    // a query response when no log entries exist: total=0, all else null
    // (including the sequential message identifier)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISTransmitterNonFunctioningLog,
      fields: [0, nil, nil, nil, nil, nil, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
      Issue.record("expected .AISTransmitterNonFunctioningLog, got \(payload)")
      return
    }

    #expect(id == nil)
    #expect(entries.isEmpty)
  }

  @Test("throws an error for an invalid reason code")
  func throwsAnErrorForAnInvalidReasonCode() async throws {
    let parser = SwiftNMEA()
    // reason code 0 is not a defined value
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISTransmitterNonFunctioningLog,
      fields: [1, 1, 3, "15052025", "081500.00", "15052025", "093000.00", 0]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .unknownValue)
  }
}
