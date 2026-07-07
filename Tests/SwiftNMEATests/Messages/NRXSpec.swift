import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.73 NRX")
struct NRXTests {
  // MARK: - .parse

  @Test("parses the example sentence group")
  func parsesTheExampleSentenceGroup() async throws {
    let parser = SwiftNMEA()
    let string = """
      $CRNRX,007,001,00,IE69,1,135600,27,06,2001,241,3,A,==========================*09\r
      $CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001.*29\r
      $CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF*0D\r
      $CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT*70\r
      $CRNRX,007,005,00,,,,,,,,,,H FORELAND TO SE^2A^2AEY BILL.^0D^0A12 HOURS FOREC*16\r
      $CRNRX,007,006,00,,,,,,,,,,AST:^0D^0A^0ASHOWERY WINDS^2C STRONGEST IN NORTH. *1C\r
      $CRNRX,007,007,00,,,,,,,,,, ^0D ^0A^0D ^0A*59\r\n
      """
    let data = string.data(using: .utf8)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 8)
    let payload = try #require((messages[7] as? Message)?.payload)
    guard
      case let .NAVTEXMessage(
        message,
        id,
        frequency,
        code,
        time,
        totalCharacters,
        badCharacters,
        isValid
      ) = payload
    else {
      Issue.record("expected .NAVTEXMessage, got \(payload)")
      return
    }

    #expect(
      message == """
        ==================================\r
        ISSUED ON SATURDAY 06 JANUARY 2001.\r
        INSHORE WATERS FORECAST TO 12 MILES\r
        OFFSHORE FROM 1700 UT* TO 0500 UTC.\r
        \r
        NORTH FORELAND TO SE**EY BILL.\r
        12 HOURS FORECAST:\r

        SHOWERY WINDS, STRONGEST IN NORTH.  \r\u{20}
        \r\u{20}

        """
    )
    #expect(id == 0)
    #expect(frequency == .freq490)
    #expect(code == "IE69")
    let components = DateComponents(
      timeZone: .gmt,
      year: 2001,
      month: 6,
      day: 27,
      hour: 13,
      minute: 56,
      second: 0
    )
    #expect(time == Calendar.current.date(from: components))
    #expect(totalCharacters == 241)
    #expect(badCharacters == 3)
    #expect(isValid)
  }

  @Test("parses a message with a null code when the source is not NAVTEX")
  func parsesAMessageWithANullCodeWhenTheSourceIsNotNAVTEX() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(
      to: "$CRNRX,001,001,00,,1,135600,27,06,2001,26,0,A,HF-MSI BODY"
    )
    let data = sentence.data(using: .utf8)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .NAVTEXMessage(message, _, _, code, _, _, _, _) = payload else {
      Issue.record("expected .NAVTEXMessage, got \(payload)")
      return
    }

    #expect(code == nil)
    #expect(message == "HF-MSI BODY")
  }

  @Test("throws an error for a missing field")
  func parseThrowsAnErrorForAMissingField()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(
        to: "$CRNRX,007,001,00,IE69,,135600,27,06,2001,241,3,A,=========================="
      ),
      applyChecksum(
        to: "$CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001."
      ),
      applyChecksum(
        to: "$CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF"
      ),
      applyChecksum(
        to: "$CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT"
      ),
      applyChecksum(
        to: "$CRNRX,007,005,00,,,,,,,,,,H FORELAND TO SE^2A^2AEY BILL.^0D^0A12 HOURS FOREC"
      ),
      applyChecksum(
        to: "$CRNRX,007,006,00,,,,,,,,,,AST:^0D^0A^0ASHOWERY WINDS^2C STRONGEST IN NORTH."
      ),
      applyChecksum(to: "$CRNRX,007,007,00,,,,,,,,,, ^0D ^0A^0D ^0A")
    ]
    let data = sentences.joined().data(using: .utf8)!
    let messages = try await parser.parse(data: data)
    #expect(messages.count == 8)

    guard let error = messages[7] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[7])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 4)
  }

  @Test("throws an error for a wrong sentence number")
  func throwsAnErrorForAWrongSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(
        to: "$CRNRX,007,001,00,IE69,1,135600,27,06,2001,241,3,A,=========================="
      ),
      applyChecksum(
        to: "$CRNRX,007,008,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001."
      ),
      applyChecksum(
        to: "$CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF"
      ),
      applyChecksum(
        to: "$CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT"
      ),
      applyChecksum(
        to: "$CRNRX,007,005,00,,,,,,,,,,H FORELAND TO SE^2A^2AEY BILL.^0D^0A12 HOURS FOREC"
      ),
      applyChecksum(
        to: "$CRNRX,007,006,00,,,,,,,,,,AST:^0D^0A^0ASHOWERY WINDS^2C STRONGEST IN NORTH. "
      ),
      applyChecksum(to: "$CRNRX,007,007,00,,,,,,,,,, ^0D ^0A^0D ^0A")
    ]
    let data = sentences.joined().data(using: .utf8)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 8)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let string = """
      $CRNRX,007,001,00,IE69,1,135600,27,06,2001,241,3,A,==========================*09\r
      $CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001.*29\r
      $CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF*0D\r
      $CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT*70\r\n
      """
    let data = string.data(using: .utf8)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 4)

    let messages = try await parser.flush(includeIncomplete: true)

    let message = try #require(messages[0] as? Message)
    guard
      case let .NAVTEXMessage(
        message,
        id,
        frequency,
        code,
        time,
        totalCharacters,
        badCharacters,
        isValid
      ) = message.payload
    else {
      Issue.record("expected .NAVTEXMessage, got \(message)")
      return
    }

    #expect(
      message == """
        ==================================\r
        ISSUED ON SATURDAY 06 JANUARY 2001.\r
        INSHORE WATERS FORECAST TO 12 MILES\r
        OFFSHORE FROM 1700 UT* TO 0500 UTC.\r
        \r
        NORT
        """
    )
    #expect(id == 0)
    #expect(frequency == .freq490)
    #expect(code == "IE69")
    let components = DateComponents(
      timeZone: .gmt,
      year: 2001,
      month: 6,
      day: 27,
      hour: 13,
      minute: 56,
      second: 0
    )
    #expect(time == Calendar.current.date(from: components))
    #expect(totalCharacters == 241)
    #expect(badCharacters == 3)
    #expect(isValid)
  }

  @Test("throws an error for a missing field")
  func flushThrowsAnErrorForAMissingField()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(
        to: "$CRNRX,007,001,00,IE69,,135600,27,06,2001,241,3,A,=========================="
      ),
      applyChecksum(
        to: "$CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001."
      ),
      applyChecksum(
        to: "$CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF"
      ),
      applyChecksum(
        to: "$CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT"
      )
    ]
    let data = sentences.joined().data(using: .utf8)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 4)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    guard let error = flushed[0] as? MessageError else {
      Issue.record("expected MessageError, got \(flushed[0])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 4)
  }
}
