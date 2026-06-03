import Nimble
import Quick

@testable import SwiftNMEA

final class MEBSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.55 MEB") {
      describe(".parse") {
        it("parses a sentence") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          // MEB has a large header, so a single encapsulated data field is
          // limited to 28 six-bit characters (21 bytes) to stay within the
          // 82-character sentence limit. data1 fits in one sentence; data2
          // spans two.
          let data1 = "interesting binary".data(using: .ascii)!
          let data2 = "A message spanning two MEB sentences.".data(using: .ascii)!
          let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 28)
          let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 28)

          let sentences1 = encapsulatedSentences(
            format: .broadcastCommandMessage,
            from: chunks1,
            fillBits: fillBits1,
            sequenceID: 0,
            otherFields: [0, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
          )
          let sentences2 = encapsulatedSentences(
            format: .broadcastCommandMessage,
            from: chunks2,
            fillBits: fillBits2,
            sequenceID: 1,
            otherFields: [1, 9_876_543_210, 14, 2, 1, nil, 0, "R"]
          )
          let data = (sentences1 + sentences2).joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(5))
          guard let payload1 = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard let payload2 = (messages[4] as? Message)?.payload else {
            fail("expected Message, got \(messages[4])")
            return
          }

          expect(payload1).to(
            equal(
              .broadcastMessage(
                sequence: 0,
                AISChannel: .noPreference,
                MMSI: 1_234_567_890,
                messageID: .addressedBinary,
                messageIndex: 3,
                broadcastBehavior: .store,
                destinationMMSI: 9_876_543_210,
                binaryStructure: .application,
                sentenceType: .command,
                data: data1
              )
            )
          )
          expect(payload2).to(
            equal(
              .broadcastMessage(
                sequence: 1,
                AISChannel: .A,
                MMSI: 9_876_543_210,
                messageID: .broadcastSafety,
                messageIndex: 2,
                broadcastBehavior: .single,
                destinationMMSI: nil,
                binaryStructure: .unstructured,
                sentenceType: .reply,
                data: data2
              )
            )
          )
        }

        it("parses a stored message with a null channel") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data = "interesting binary".data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)

          // channel (field 3) is null; broadcast behaviour (field 7) is store (0)
          let sentences = encapsulatedSentences(
            format: .broadcastCommandMessage,
            from: chunks,
            fillBits: fillBits,
            sequenceID: 0,
            otherFields: [nil, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
          )
          let sentenceData = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case let .broadcastMessage(_, AISChannel, _, _, _, behavior, _, _, _, _) = payload
          else {
            fail("expected .broadcastMessage, got \(payload)")
            return
          }

          expect(AISChannel).to(beNil())
          expect(behavior).to(equal(.store))
        }

        it("throws an error for a missing field") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data =
            "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
            .data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
          let sentences = [
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .broadcastCommandMessage,
              fields: [
                2, 1, 1,
                1, nil, 1, 1, 1,
                9_876_543_210, 1, "R",
                chunks[0], fillBits
              ]
            ),
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .broadcastCommandMessage,
              fields: [
                2, 2, 1,
                1, nil, 1, 1, 1,
                9_876_543_210, 1, "R",
                chunks[1], fillBits
              ]
            )
          ]
          let sentenceData = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(4))

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(4))

          guard let error = messages[3] as? MessageError else {
            fail("expected MessageError, got \(messages[3])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(4))
        }

        it("throws an error for an incorrect sentence number") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data =
            "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
            .data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
          let sentences = [
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .broadcastCommandMessage,
              fields: [
                2, 1, 1,
                1, 1_234_567_890, 1, 1, 1,
                9_876_543_210, 1, "R",
                chunks[0], fillBits
              ]
            ),
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .broadcastCommandMessage,
              fields: [
                2, 3, 1,
                1, 1_234_567_890, 1, 1, 1,
                9_876_543_210, 1, "R",
                chunks[1], fillBits
              ]
            )
          ]
          let sentenceData = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

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
        it("flushes incomplete sentences") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data =
            "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
            .data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)

          let sentences = encapsulatedSentences(
            format: .broadcastCommandMessage,
            from: chunks,
            fillBits: fillBits,
            sequenceID: 0,
            otherFields: [0, 1_234_567_890, 6, 3, 0, 9_876_543_210, 1, "C"]
          )
          let sentenceData = sentences[0].data(using: .ascii)!

          let parsed = try await parser.parse(data: sentenceData)
          expect(parsed).to(haveCount(1))

          let messages = try await parser.flush(includeIncomplete: true)
          expect(messages).to(haveCount(1))

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          guard
            case let .broadcastMessage(
              sequence,
              AISChannel,
              MMSI,
              messageID,
              messageIndex,
              broadcastBehavior,
              destinationMMSI,
              binaryStructure,
              sentenceType,
              actualData
            ) = message.payload
          else {
            fail("expected .broadcastMessage, got \(message)")
            return
          }

          expect(sequence).to(equal(0))
          expect(AISChannel).to(equal(.noPreference))
          expect(MMSI).to(equal(1_234_567_890))
          expect(messageID).to(equal(.addressedBinary))
          expect(messageIndex).to(equal(3))
          expect(broadcastBehavior).to(equal(.store))
          expect(destinationMMSI).to(equal(9_876_543_210))
          expect(binaryStructure).to(equal(.application))
          expect(sentenceType).to(equal(.command))
          expect(actualData).to(
            equal("123456789012345678901".data(using: .ascii)!)
          )
        }
      }

      it("throws an error for a missing field") {
        let parser = SwiftNMEA()
        let sixBit = SixBitCoder()

        let data =
          "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
          .data(using: .ascii)!
        let (chunks, fillBits) = sixBit.encode(data, chunkSize: 28)
        let sentence = createSentence(
          delimiter: .encapsulated,
          talker: .commVHF,
          format: .broadcastCommandMessage,
          fields: [
            2, 1, 1,
            1, 1_234_567_890, 1, 1, nil,
            9_876_543_210, 1, "R",
            chunks[0], fillBits
          ]
        )
        let sentenceData = sentence.data(using: .ascii)!
        let parsed = try await parser.parse(data: sentenceData)

        expect(parsed).to(haveCount(1))

        let flushed = try await parser.flush(includeIncomplete: true)
        expect(flushed).to(haveCount(1))

        guard let error = flushed[0] as? MessageError else {
          fail("expected MessageError, got \(flushed[0])")
          return
        }
        expect(error.type).to(equal(.missingRequiredValue))
        expect(error.fieldNumber).to(equal(7))
      }
    }
  }
}
