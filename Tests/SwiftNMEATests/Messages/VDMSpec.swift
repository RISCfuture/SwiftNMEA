import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class VDMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.90 VDM") {
      describe(".parse") {
        let VDLBinaryData = """
          000001
          100000
          000000
          000000
          000000
          011111
          110000
          000001
          011001
          100100
          000001
          111011
          111110
          100100
          100000
          000010
          111010
          001010
          000100
          000011
          101111
          111010
          111111
          101010
          000000
          000101
          111001
          000100
          """
        let VDLBytes =
          VDLBinaryData
          .replacing(.newlineSequence, with: "")
          .chunks(ofCount: 8)
          .map { UInt8($0, radix: 2)! }
        let VDLData = Data(VDLBytes)

        it("parses a sentence") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data1 = "This is some very interesting binary data".data(using: .ascii)!
          let data2 = "Each message must be no more than 60 characters to fit in a single sentence"
            .data(using: .ascii)!
          let (chunks1, fillBits1) = sixBit.encode(data1, chunkSize: 60)
          let (chunks2, fillBits2) = sixBit.encode(data2, chunkSize: 60)

          let sentences1 = encapsulatedSentences(
            format: .VDLMessage,
            from: chunks1,
            fillBits: fillBits1,
            sequenceID: 0,
            otherFields: ["A"]
          )
          let sentences2 = encapsulatedSentences(
            format: .VDLMessage,
            from: chunks2,
            fillBits: fillBits2,
            sequenceID: 1,
            otherFields: ["B"]
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
          expect(payload1).to(equal(.VDLMessage(data1, channel: .A)))
          expect(payload2).to(equal(.VDLMessage(data2, channel: .B)))
        }

        it("parses a 62-character (46-byte) sentence when some fields are nil") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data = "1234567890123456789012345678901234567890123456".data(using: .ascii)!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 62)
          let sentence = createSentence(
            delimiter: .encapsulated,
            talker: .commVHF,
            format: .VDLMessage,
            fields: [1, 1, nil, nil, chunks[0], fillBits]
          )
          let sentenceData = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          guard case .VDLMessage(let actualData, let channel) = payload else {
            fail("expected .VDLMessage, got \(payload)")
            return
          }
          expect(actualData).to(equal(data))
          expect(channel).to(beNil())
        }

        it("throws an error for an incorrect sentence number") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data = "This data is exactly 62 characters long. This data is exactly ".data(
            using: .ascii
          )!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)
          let sentences = [
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .VDLMessage,
              fields: [2, 1, nil, nil, chunks[0], fillBits]
            ),
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .VDLMessage,
              fields: [2, 3, nil, nil, chunks[1], fillBits]
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

        it("parses the first example from the spec") {
          let parser = SwiftNMEA()
          let sentence = applyChecksum(to: "!AIVDM,1,1,,A,1P000Oh1IT1svTP2r:43grwb05q4,0")
          let sentenceData = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          expect(payload).to(equal(.VDLMessage(VDLData, channel: .A)))
        }

        it("parses the second example from the spec") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(to: "!AIVDM,2,1,7,A,1P000Oh1IT1svT,0"),
            applyChecksum(to: "!AIVDM,2,2,7,A,P2r:43grwb05q4,0")
          ]
          let sentenceData = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          expect(payload).to(equal(.VDLMessage(VDLData, channel: .A)))
        }

        it("parses the third example from the spec") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(to: "!AIVDM,2,1,9,A,1P000Oh1IT1svTP2r:43,0"),
            applyChecksum(to: "!AIVDM,2,2,9,A,grwb05q4,0")
          ]
          let sentenceData = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: sentenceData)

          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          expect(payload).to(equal(.VDLMessage(VDLData, channel: .A)))
        }
      }

      describe(".flush") {
        it("flushes incomplete sentences") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let data = "12345678901234567890123456789012345678901234567890123456789012".data(
            using: .ascii
          )!
          let (chunks, fillBits) = sixBit.encode(data, chunkSize: 60)

          let sentences = encapsulatedSentences(
            format: .VDLMessage,
            from: chunks,
            fillBits: fillBits,
            sequenceID: 0,
            otherFields: ["A"]
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
          guard case .VDLMessage(let message, let channel) = message.payload else {
            fail("expected .VDLMessage, got \(message)")
            return
          }

          expect(channel).to(equal(.A))
          expect(message).to(
            equal("12345678901234567890123456789012345678901234".data(using: .ascii)!)
          )
        }
      }
    }
  }
}
