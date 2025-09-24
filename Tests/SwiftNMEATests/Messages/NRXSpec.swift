import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class NRXSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.63 NRX") {
      describe(".parse") {
        it("parses the example sentence group") {
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

          expect(messages).to(haveCount(8))
          guard let payload = (messages[7] as? Message)?.payload else {
            fail("expected Message, got \(messages[7])")
            return
          }
          guard
            case .NAVTEXMessage(
              let message,
              let id,
              let frequency,
              let code,
              let time,
              let totalCharacters,
              let badCharacters,
              let isValid
            ) = payload
          else {
            fail("expected .NAVTEXMessage, got \(payload)")
            return
          }

          expect(message).to(
            equal(
              """
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
          )
          expect(id).to(equal(0))
          expect(frequency).to(equal(.freq490))
          expect(code).to(equal("IE69"))
          let components = DateComponents(
            timeZone: .gmt,
            year: 2001,
            month: 6,
            day: 27,
            hour: 13,
            minute: 56,
            second: 0
          )
          expect(time).to(equal(Calendar.current.date(from: components)))
          expect(totalCharacters).to(equal(241))
          expect(badCharacters).to(equal(3))
          expect(isValid).to(beTrue())
        }

        it("throws an error for a missing field") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(
              to: "$CRNRX,007,001,00,,1,135600,27,06,2001,241,3,A,=========================="
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
          expect(messages).to(haveCount(8))

          guard let error = messages[7] as? MessageError else {
            fail("expected MessageError, got \(messages[7])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(3))
        }

        it("throws an error for a wrong sentence number") {
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

          expect(messages).to(haveCount(8))
          guard let error = messages[2] as? MessageError else {
            fail("expected MessageError, got \(messages[2])")
            return
          }
          expect(error.type).to(equal(.wrongSentenceNumber))
          expect(error.fieldNumber).to(equal(1))
        }
      }

      describe(".flush") {
        it("flushes incomplete sentences") {
          let parser = SwiftNMEA()
          let string = """
            $CRNRX,007,001,00,IE69,1,135600,27,06,2001,241,3,A,==========================*09\r
            $CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001.*29\r
            $CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF*0D\r
            $CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT*70\r\n
            """
          let data = string.data(using: .utf8)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(4))

          let messages = try await parser.flush(includeIncomplete: true)

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          guard
            case .NAVTEXMessage(
              let message,
              let id,
              let frequency,
              let code,
              let time,
              let totalCharacters,
              let badCharacters,
              let isValid
            ) = message.payload
          else {
            fail("expected .NAVTEXMessage, got \(message)")
            return
          }

          expect(message).to(
            equal(
              """
              ==================================\r
              ISSUED ON SATURDAY 06 JANUARY 2001.\r
              INSHORE WATERS FORECAST TO 12 MILES\r
              OFFSHORE FROM 1700 UT* TO 0500 UTC.\r
              \r
              NORT
              """
            )
          )
          expect(id).to(equal(0))
          expect(frequency).to(equal(.freq490))
          expect(code).to(equal("IE69"))
          let components = DateComponents(
            timeZone: .gmt,
            year: 2001,
            month: 6,
            day: 27,
            hour: 13,
            minute: 56,
            second: 0
          )
          expect(time).to(equal(Calendar.current.date(from: components)))
          expect(totalCharacters).to(equal(241))
          expect(badCharacters).to(equal(3))
          expect(isValid).to(beTrue())
        }

        it("throws an error for a missing field") {
          let parser = SwiftNMEA()
          let string = """
            $CRNRX,007,001,00,,1,135600,27,06,2001,241,3,A,==========================*0A\r
            $CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001.*29\r
            $CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF*0D\r
            $CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT*70\r\n
            """
          let data = string.data(using: .utf8)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(4))

          let flushed = try await parser.flush(includeIncomplete: true)
          expect(flushed).to(haveCount(1))

          guard let error = flushed[0] as? MessageError else {
            fail("expected MessageError, got \(flushed[0])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(3))
        }
      }
    }
  }
}
