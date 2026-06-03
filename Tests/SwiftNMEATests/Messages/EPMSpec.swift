import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class EPMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.32 EPM") {
      describe(".parse") {
        it("parses a multi-sentence command and concatenates the value") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .ECDIS,
              format: .equipmentPropertyLong,
              fields: [
                2, 1, 98, "C", "AI", "503123450", 1234, "This-is-an-example-of-a-long-parameter"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .ECDIS,
              format: .equipmentPropertyLong,
              fields: [
                2, 2, 98, "C", "AI", "503123450", 1234, "-which-continues-over-multiple-messages"
              ]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          guard
            case let .equipmentPropertyLong(type, reference, property, value) = payload
          else {
            fail("expected .equipmentPropertyLong, got \(payload)")
            return
          }

          expect(type).to(equal(.command))
          expect(reference.type).to(equal(.automaticID))
          expect(reference.uniqueID).to(equal("503123450"))
          expect(property.rawValue).to(equal(1234))
          expect(value).to(
            equal("This-is-an-example-of-a-long-parameter-which-continues-over-multiple-messages")
          )
        }

        it("decodes escaped reserved characters in the value") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .ECDIS,
            format: .equipmentPropertyLong,
            fields: [1, 1, 25, "R", "AI", "503123450", 101, "a^2Cb"]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case let .equipmentPropertyLong(type, _, _, value) = payload else {
            fail("expected .equipmentPropertyLong, got \(payload)")
            return
          }

          expect(type).to(equal(.reply))
          expect(value).to(equal("a,b"))
        }

        it("parses a null unique identifier") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .ECDIS,
            format: .equipmentPropertyLong,
            fields: [1, 1, 12, "C", "AI", nil, 7, "value"]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case let .equipmentPropertyLong(_, reference, _, _) = payload else {
            fail("expected .equipmentPropertyLong, got \(payload)")
            return
          }

          expect(reference.uniqueID).to(beNil())
        }

        it("throws an error for a negative property identifier") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .ECDIS,
            format: .equipmentPropertyLong,
            fields: [1, 1, 12, "C", "AI", "503123450", -5, "value"]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.badNumericValue))
          expect(error.fieldNumber).to(equal(6))
        }

        it("rejects an out-of-order sentence instead of concatenating it") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .ECDIS,
              format: .equipmentPropertyLong,
              fields: [3, 1, 98, "C", "AI", "503123450", 1234, "first-"]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .ECDIS,
              format: .equipmentPropertyLong,
              fields: [3, 3, 98, "C", "AI", "503123450", 1234, "third"]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .ECDIS,
              format: .equipmentPropertyLong,
              fields: [3, 2, 98, "C", "AI", "503123450", 1234, "second-"]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          // Sentence 3 appends after sentence 1; sentence 2 then arrives out of
          // order. It must be rejected rather than concatenated in the wrong
          // position (which would silently corrupt the reassembled value).
          guard let error = messages.last as? MessageError else {
            fail("expected MessageError, got \(messages.last as Any)")
            return
          }
          expect(error.type).to(equal(.wrongSentenceNumber))
          expect(error.fieldNumber).to(equal(1))
        }
      }

      describe(".flush") {
        it("flushes an incomplete message") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .ECDIS,
            format: .equipmentPropertyLong,
            fields: [2, 1, 98, "C", "AI", "503123450", 1234, "first-half"]
          )
          let data = sentence.data(using: .ascii)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(1))

          let flushed = try await parser.flush(includeIncomplete: true)
          expect(flushed).to(haveCount(1))

          guard let message = flushed[0] as? Message else {
            fail("expected Message, got \(flushed[0])")
            return
          }
          guard case let .equipmentPropertyLong(_, _, _, value) = message.payload else {
            fail("expected .equipmentPropertyLong, got \(message.payload)")
            return
          }
          expect(value).to(equal("first-half"))
        }
      }
    }
  }
}
