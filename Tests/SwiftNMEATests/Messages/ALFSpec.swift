import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ALFSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.14 ALF") {
      describe(".parse") {
        context("single-sentence message") {
          it("parses the spec example") {
            let parser = SwiftNMEA()
            // $IIALF,1,1,0,124304.50,A,W,A,,3052,1,1,0,LOST TARGET
            let sentence = createSentence(
              delimiter: .parametric,
              talker: .integratedInstrumentation,
              format: .alert,
              fields: [1, 1, 0, "124304.50", "A", "W", "A", nil, 3052, 1, 1, 0, "LOST TARGET"]
            )
            let data = sentence.data(using: .ascii)!
            let messages = try await parser.parse(data: data)

            expect(messages).to(haveCount(2))
            guard let payload = (messages[1] as? Message)?.payload else {
              fail("expected Message, got \(messages[1])")
              return
            }

            guard
              case let .alert(
                identifier,
                sequentialMessageID: sequentialMessageID,
                time: time,
                category: category,
                priority: priority,
                state: state,
                revisionCounter: revisionCounter,
                escalationCounter: escalationCounter,
                title: title,
                description: description
              ) = payload
            else {
              fail("expected .alert, got \(payload)")
              return
            }

            expect(identifier.manufacturerMnemonic).to(beNil())
            expect(identifier.identifier).to(equal(3052))
            expect(identifier.instance).to(equal(1))
            expect(sequentialMessageID).to(equal(0))
            expect(time).toNot(beNil())
            expect(category).to(equal(.A))
            expect(priority).to(equal(.warning))
            expect(state).to(equal(.activeAcknowledged))
            expect(revisionCounter).to(equal(1))
            expect(escalationCounter).to(equal(0))
            expect(title).to(equal("LOST TARGET"))
            expect(description).to(beNil())
          }

          it("allows null category, priority, and state for a normal alert") {
            let parser = SwiftNMEA()
            let sentence = createSentence(
              delimiter: .parametric,
              talker: .integratedInstrumentation,
              format: .alert,
              fields: [1, 1, nil, nil, nil, nil, "N", nil, 3052, nil, 1, 0, "NORMAL"]
            )
            let data = sentence.data(using: .ascii)!
            let messages = try await parser.parse(data: data)

            expect(messages).to(haveCount(2))
            guard let payload = (messages[1] as? Message)?.payload else {
              fail("expected Message, got \(messages[1])")
              return
            }

            guard
              case let .alert(
                identifier,
                sequentialMessageID: sequentialMessageID,
                time: time,
                category: category,
                priority: priority,
                state: state,
                revisionCounter: _,
                escalationCounter: _,
                title: title,
                description: description
              ) = payload
            else {
              fail("expected .alert, got \(payload)")
              return
            }

            expect(identifier.instance).to(beNil())
            expect(sequentialMessageID).to(beNil())
            expect(time).to(beNil())
            expect(category).to(beNil())
            expect(priority).to(beNil())
            expect(state).to(equal(.normal))
            expect(title).to(equal("NORMAL"))
            expect(description).to(beNil())
          }
        }

        context("two-sentence message") {
          it("combines the title and description") {
            let parser = SwiftNMEA()
            // $IIALF,2,1,1,081950.10,B,A,S,XYZ,010512,1,2,0,HEADING LOST
            // $IIALF,2,2,1,,,,,XYZ,010512,1,2,0,NO SYSTEM HEADING AVAILABLE
            let sentences = [
              createSentence(
                delimiter: .parametric,
                talker: .integratedInstrumentation,
                format: .alert,
                fields: [2, 1, 1, "081950.10", "B", "A", "S", "XYZ", 10512, 1, 2, 0, "HEADING LOST"]
              ),
              createSentence(
                delimiter: .parametric,
                talker: .integratedInstrumentation,
                format: .alert,
                fields: [
                  2, 2, 1, nil, nil, nil, nil, "XYZ", 10512, 1, 2, 0,
                  "NO SYSTEM HEADING AVAILABLE"
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
              case let .alert(
                identifier,
                sequentialMessageID: _,
                time: _,
                category: category,
                priority: priority,
                state: state,
                revisionCounter: _,
                escalationCounter: _,
                title: title,
                description: description
              ) = payload
            else {
              fail("expected .alert, got \(payload)")
              return
            }

            expect(identifier.manufacturerMnemonic).to(equal("XYZ"))
            expect(identifier.identifier).to(equal(10512))
            expect(category).to(equal(.B))
            expect(priority).to(equal(.alarm))
            expect(state).to(equal(.activeSilenced))
            expect(title).to(equal("HEADING LOST"))
            expect(description).to(equal("NO SYSTEM HEADING AVAILABLE"))
          }
        }

        it("throws for a negative alert identifier") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .integratedInstrumentation,
            format: .alert,
            fields: [1, 1, 0, "124304.50", "A", "W", "A", nil, -5, 1, 1, 0, "LOST TARGET"]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.badValue))
          expect(error.fieldNumber).to(equal(8))
        }

        it("throws for an unknown alert state") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .integratedInstrumentation,
            format: .alert,
            fields: [1, 1, 0, "124304.50", "A", "W", "Z", nil, 3052, 1, 1, 0, "LOST TARGET"]
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

      describe(".flush") {
        it("flushes an incomplete multi-sentence message") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .integratedInstrumentation,
            format: .alert,
            fields: [2, 1, 1, "081950.10", "B", "A", "S", "XYZ", 10512, 1, 2, 0, "HEADING LOST"]
          )
          let data = sentence.data(using: .ascii)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(1))

          let messages = try await parser.flush(includeIncomplete: true)
          expect(messages).to(haveCount(1))
          guard let payload = (messages[0] as? Message)?.payload else {
            fail("expected Message, got \(messages[0])")
            return
          }

          guard
            case let .alert(_, _, _, _, _, _, _, _, title: title, description: description) =
              payload
          else {
            fail("expected .alert, got \(payload)")
            return
          }
          expect(title).to(equal("HEADING LOST"))
          expect(description).to(beNil())
        }
      }
    }
  }
}
