import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class TUTSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.86 TUT") {
      describe(".parse") {
        it("parses the proprietary example from the spec") {
          let parser = SwiftNMEA()
          let sentence = "$SDTUT,SD,01,01,1,PXYZ,02*6D\r\n"
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard
            case .multiLanguageText(let source, let text, let data, let translationCode) = payload
          else {
            fail("expected .multiLanguageText, got \(payload)")
            return
          }

          expect(source).to(equal(.depthSounder))
          expect(text).to(beNil())
          expect(data).to(haveCount(1))
          expect(data[0]).to(equal(0x02))
          expect(translationCode).to(equal("PXYZ"))
        }

        it("parses the Unicode example from the spec") {
          let parser = SwiftNMEA()
          let sentence = "$INTUT,SD,01,01,1,U,6D45702C5371967A*5D\r\n"
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case .multiLanguageText(let source, let text, _, let translationCode) = payload
          else {
            fail("expected .multiLanguageText, got \(payload)")
            return
          }

          expect(source).to(equal(.depthSounder))
          expect(text).to(equal("浅瀬危険"))
          expect(translationCode).to(equal("U"))
        }

        it("parses the ASCII example from the spec") {
          let parser = SwiftNMEA()
          let sentence = "$INTUT,SD,01,01,1,A,5368616C6C6F7720576174657221*4B\r\n"
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case .multiLanguageText(let source, let text, _, let translationCode) = payload
          else {
            fail("expected .multiLanguageText, got \(payload)")
            return
          }

          expect(source).to(equal(.depthSounder))
          expect(text).to(equal("Shallow Water!"))
          expect(translationCode).to(equal("A"))
        }

        it("throws an error for invalid encoded data") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commVHF,
            format: .multiLanguageText,
            // invalid high-bit characters
            fields: [
              "SD", "01", "01", 1, "A",
              "not a valid hex string!"
            ]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.badValue))
          expect(error.fieldNumber).to(equal(5))
        }

        it("throws an error for an incorrect sentence number") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "01", 1, "A", "5368616C6C6F7720"]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "04", 1, "A", "576174657221"]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(3))
          guard let error = messages[2] as? MessageError else {
            fail("expected MessageError, got \(messages[2])")
            return
          }
          expect(error.type).to(equal(.wrongSentenceNumber))
          expect(error.fieldNumber).to(equal(1))
        }
      }

      describe(".flush") {
        it("flushes incomplete messages") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "01", 1, "A", "5368616C6C6F7720"]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "02", 1, "A", "576174657221"]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let parsed = try await parser.parse(data: data)

          expect(parsed).to(haveCount(2))

          let messages = try await parser.flush(includeIncomplete: true)
          expect(messages).to(haveCount(1))

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          guard
            case .multiLanguageText(let source, let text, _, let translationCode) = message.payload
          else {
            fail("expected .multiLanguageText, got \(message)")
            return
          }

          expect(source).to(equal(.depthSounder))
          expect(text).to(equal("Shallow Water!"))
          expect(translationCode).to(equal("A"))
        }

        it("throws an error for invalid encoded data") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "01", 1, "A", "not a valid hex string!"]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .integratedNavigation,
              format: .multiLanguageText,
              fields: ["SD", "03", "02", 1, "A", "576174657221"]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let _ = try await parser.parse(data: data)

          let flushed = try await parser.flush(includeIncomplete: true)
          expect(flushed).to(haveCount(1))

          guard let error = flushed[0] as? MessageError else {
            fail("expected MessageError, got \(flushed[0])")
            return
          }
          expect(error.type).to(equal(.badValue))
          expect(error.fieldNumber).to(equal(5))
        }
      }
    }
  }
}
