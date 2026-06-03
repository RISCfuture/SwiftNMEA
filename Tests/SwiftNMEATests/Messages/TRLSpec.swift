import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class TRLSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.106 TRL") {
      it("parses a single log entry") {
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

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
          fail("expected .AISTransmitterNonFunctioningLog, got \(payload)")
          return
        }

        expect(id).to(equal(3))
        expect(entries).to(haveCount(1))

        let entry = entries[0]
        expect(entry.number).to(equal(1))
        expect(entry.reason).to(equal(.powerOff))

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
        expect(entry.switchOff).to(equal(switchOff))
        expect(entry.switchOn).to(equal(switchOn))
      }

      it("assembles a multi-entry log") {
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
        guard let payload = messages.compactMap({ ($0 as? Message)?.payload }).last else {
          fail("expected an assembled Message, got \(messages)")
          return
        }
        guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
          fail("expected .AISTransmitterNonFunctioningLog, got \(payload)")
          return
        }

        expect(id).to(equal(4))
        expect(entries).to(haveCount(2))
        expect(entries[0].number).to(equal(1))
        expect(entries[0].reason).to(equal(.powerOff))
        expect(entries[1].number).to(equal(2))
        expect(entries[1].reason).to(equal(.equipmentMalfunction))
      }

      it("parses an empty log with null fields") {
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

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .AISTransmitterNonFunctioningLog(id, entries) = payload else {
          fail("expected .AISTransmitterNonFunctioningLog, got \(payload)")
          return
        }

        expect(id).to(beNil())
        expect(entries).to(beEmpty())
      }

      it("throws an error for an invalid reason code") {
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

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
