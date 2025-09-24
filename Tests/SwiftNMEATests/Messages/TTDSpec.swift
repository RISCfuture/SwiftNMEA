import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class TTDSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.84 TTD") {
      describe(".parse") {
        it("parses a sentence") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let target = Data([
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
          ])
          let (chunks, fillBits) = sixBit.encode(target, chunkSize: 60)

          let sentences = encapsulatedSentences(
            format: .trackedTargets,
            from: chunks,
            fillBits: fillBits,
            sequenceID: 0,
            otherFields: [],
            hex: true
          )
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case .trackedTargets(let targets) = payload else {
            fail("expected .trackedTargets, got \(payload)")
            return
          }

          expect(targets).to(haveCount(1))
          expect(targets[0].protocolVersion).to(equal(0))
          expect(targets[0].number).to(equal(123))
          expect(targets[0].bearing!.angle).to(equal(.init(value: 123.4, unit: .degrees)))
          expect(targets[0].bearing!.reference).to(equal(.true))
          expect(targets[0].speed).to(equal(.init(value: 15.5, unit: .knots)))
          expect(targets[0].course!.value).to(beCloseTo(135.7, within: 0.1))
          expect(targets[0].heading).to(beNil())
          expect(targets[0].isRadarTarget).to(beTrue())
          expect(targets[0].status).to(equal(.activatedNoAlarm))
          expect(targets[0].isTestTarget).to(beFalse())
          expect(targets[0].distance).to(equal(.init(value: 163, unit: .nauticalMiles)))
          expect(targets[0].speedCourseRelative).to(beTrue())
          expect(targets[0].waterStabilized).to(beFalse())
          expect(targets[0].correlationNumber).to(equal(128))
        }

        it("throws an error for an incorrect sentence number") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let target = Data([
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
          ])
          let (chunks, fillBits) = sixBit.encode(target, chunkSize: 60)

          let sentences = [
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .trackedTargets,
              fields: ["02", "01", 1, chunks[0], fillBits]
            ),
            createSentence(
              delimiter: .encapsulated,
              talker: .commVHF,
              format: .trackedTargets,
              fields: ["02", "03", 1, chunks[1], fillBits]
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
        it("flushes incomplete sentences") {
          let parser = SwiftNMEA()
          let sixBit = SixBitCoder()

          let targets = Data([
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
            0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF
          ])
          let (chunks, fillBits) = sixBit.encode(targets, chunkSize: 60)

          let sentences = encapsulatedSentences(
            format: .trackedTargets,
            from: chunks,
            fillBits: fillBits,
            sequenceID: 0,
            otherFields: [],
            hex: true
          )
          let data = sentences[0...1].joined().data(using: .ascii)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(2))

          let messages = try await parser.flush(includeIncomplete: true)
          expect(messages).to(haveCount(1))

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          guard case .trackedTargets(let targets) = message.payload else {
            fail("expected .trackedTargets, got \(message)")
            return
          }

          expect(targets).to(haveCount(7))
        }
      }
    }
  }
}
