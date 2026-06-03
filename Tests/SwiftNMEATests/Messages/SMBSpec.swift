import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SMBSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.96 SMB") {
      describe(".parse") {
        it("parses a multi-sentence message and decodes code delimiters") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(to: "$CSSMB,002,001,0,123456,FROM:MRCC^0D^0A"),
            applyChecksum(to: "$CSSMB,002,002,0,123456,TO:ALL SHIPS")
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          // two echoed sentences, then the assembled message on the last sentence
          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          expect(payload).to(
            equal(
              .safetyNETMessageBody(
                "FROM:MRCC\r\nTO:ALL SHIPS",
                uniqueMessageNumber: 123_456,
                identifier: 0
              )
            )
          )
        }

        it("parses a single sentence with null sentence number and identifier") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETMessageBody,
            fields: ["001", nil, nil, 654_321, "SINGLE LINE MESSAGE"]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          expect(payload).to(
            equal(
              .safetyNETMessageBody(
                "SINGLE LINE MESSAGE",
                uniqueMessageNumber: 654_321,
                identifier: nil
              )
            )
          )
        }

        it("throws an error for an out-of-range sentence number") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(to: "$CSSMB,002,001,0,123456,FIRST"),
            applyChecksum(to: "$CSSMB,002,003,0,123456,THIRD")
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
        it("flushes an incomplete message") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETMessageBody,
            fields: ["003", "001", 5, 222_333, "PARTIAL BODY"]
          )
          let data = sentence.data(using: .ascii)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(1))

          let messages = try await parser.flush(includeIncomplete: true)
          expect(messages).to(haveCount(1))

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          expect(message.payload).to(
            equal(
              .safetyNETMessageBody(
                "PARTIAL BODY",
                uniqueMessageNumber: 222_333,
                identifier: 5
              )
            )
          )
        }
      }
    }
  }
}
