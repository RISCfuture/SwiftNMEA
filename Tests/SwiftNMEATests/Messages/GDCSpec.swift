import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GDCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.39 GDC") {
      describe(".parse") {
        it("parses a single-sentence message") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSDifferentialCorrection,
            fields: [
              1, 1, 1,
              12, -1.5, 42, 432_000, 1234.5, 7.25, 5
            ]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case let .GNSSDifferentialCorrection(corrections, totalSatellites) = payload else {
            fail("expected .GNSSDifferentialCorrection, got \(payload)")
            return
          }

          expect(totalSatellites).to(equal(1))
          expect(corrections).to(haveCount(1))

          let correction = corrections[0]
          guard case let .GPS(id, signal) = correction.satellite else {
            fail("expected .GPS, got \(correction.satellite)")
            return
          }
          expect(id).to(equal(12))
          expect(signal).to(equal(.L2C_M))
          expect(correction.pseudorangeCorrection).to(equal(.init(value: -1.5, unit: .meters)))
          expect(correction.issueOfData).to(equal(42))
          expect(correction.epochTime).to(equal(.init(value: 432_000, unit: .seconds)))
          expect(correction.modifiedZCount).to(equal(.init(value: 1234.5, unit: .seconds)))
          expect(correction.UDRE).to(equal(.init(value: 7.25, unit: .meters)))
        }

        it("accumulates corrections across multiple sentences") {
          let parser = SwiftNMEA()
          let first = createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSDifferentialCorrection,
            fields: [2, 1, 2, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
          )
          let second = createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSDifferentialCorrection,
            fields: [2, 2, 2, 17, 2.5, 43, 432_006, 1240.0, 3.0, 1]
          )
          let data = (first + second).data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          // sentence echo + sentence echo + completed message
          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          guard case let .GNSSDifferentialCorrection(corrections, totalSatellites) = payload else {
            fail("expected .GNSSDifferentialCorrection, got \(payload)")
            return
          }

          expect(totalSatellites).to(equal(2))
          expect(corrections).to(haveCount(2))
          let ids = corrections.compactMap { correction -> Int? in
            guard case let .GPS(id, _) = correction.satellite else { return nil }
            return id
          }
          expect(ids).to(contain(12, 17))
        }

        it("throws an error for an invalid signal ID") {
          let parser = SwiftNMEA()
          // GPS signal IDs only range 0–8; 9 is reserved/invalid.
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSDifferentialCorrection,
            fields: [1, 1, 1, 12, -1.5, 42, 432_000, 1234.5, 7.25, 9]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.unknownValue))
          expect(error.fieldNumber).to(equal(9))
        }

        it("throws an error for the disallowed combined-GNSS talker") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .GNSS,
            format: .GNSSDifferentialCorrection,
            fields: [1, 1, 1, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.unknownTalker))
        }
      }

      describe(".flush") {
        it("flushes incomplete messages") {
          let parser = SwiftNMEA()
          let first = createSentence(
            delimiter: .parametric,
            talker: .GPS,
            format: .GNSSDifferentialCorrection,
            fields: [2, 1, 2, 12, -1.5, 42, 432_000, 1234.5, 7.25, 5]
          )
          let data = first.data(using: .ascii)!
          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(1))

          let flushed = try await parser.flush(includeIncomplete: true)
          expect(flushed).to(haveCount(1))

          guard let payload = (flushed[0] as? Message)?.payload else {
            fail("expected Message, got \(flushed[0])")
            return
          }
          guard case let .GNSSDifferentialCorrection(corrections, _) = payload else {
            fail("expected .GNSSDifferentialCorrection, got \(payload)")
            return
          }
          expect(corrections).to(haveCount(1))
        }
      }
    }
  }
}
