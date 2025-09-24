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

          let data1 = "This is some very interesting binary data".data(using: .ascii)!
          let data2 =
            "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
            .data(using: .ascii)!
          let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 82)
          let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 82)

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

        it("throws an error for a missing field") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data =
            "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
            .data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 82)
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
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 82)
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
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 82)

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
            case .broadcastMessage(
              let sequence,
              let AISChannel,
              let MMSI,
              let
                messageID,
              let messageIndex,
              let
                broadcastBehavior,
              let
                destinationMMSI,
              let
                binaryStructure,
              let
                sentenceType,
              let actualData
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
            equal(
              "1234567890123456789012345678901234567890123456789012345678901".data(using: .ascii)!
            )
          )
        }
      }

      it("throws an error for a missing field") {
        let parser = SwiftNMEA()
        let sixBit = SixBitCoder()

        let data =
          "Each message must be no more than 82 characters. Each message must be no more than 82 characters."
          .data(using: .ascii)!
        let (chunks, fillBits) = sixBit.encode(data, chunkSize: 82)
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
