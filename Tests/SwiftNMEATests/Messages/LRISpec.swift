import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class LRISpec: AsyncSpec {
  override static func spec() {
    describe("8.3.54 LRI and friends") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let LRI = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISLongRangeInterrogation,
          fields: [
            1, 0, 1_234_567_890, nil,
            "3530.00", "N", "12115.00", "W",
            "3400.00", "N", "12030.00", "W"
          ]
        )
        let LRF = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISLongRangeFunction,
          fields: [
            1, 1_234_567_890, "HAIL MARY",
            "ABCEFIOPW", nil
          ]
        )
        let data = LRI.data(using: .ascii)! + LRF.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(3))
        guard let payload = (messages[2] as? Message)?.payload else {
          fail("expected Message, got \(messages[2])")
          return
        }
        guard
          case .AISLongRangeInterrogation(
            let replyLogic,
            let requestorMMSI,
            let requestorName,
            let destination,
            let functions
          ) =
            payload
        else {
          fail("expected .AISLongRangeInterrogation, got \(payload)")
          return
        }

        expect(replyLogic).to(equal(.normal))
        expect(requestorMMSI).to(equal(1_234_567_890))
        expect(requestorName).to(equal("HAIL MARY"))
        expect(destination).to(
          equal(
            .area(
              .init(
                northeast: .init(latitude: 35.5, longitude: -121.25),
                southwest: .init(latitude: 34.0, longitude: -120.5)
              )
            )
          )
        )
        expect(functions).to(
          equal(
            .init([
              .shipID,
              .dateTime,
              .position,
              .course,
              .speed,
              .destination,
              .draught,
              .cargo,
              .soulsOnboard
            ])
          )
        )
      }

      it("throws an error if a duplicate sentence is received") {
        let parser = SwiftNMEA()
        let LRI = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISLongRangeInterrogation,
          fields: [
            1, 0, 1_234_567_890, nil,
            "3530.00", "N", "12115.00", "W",
            "3400.00", "N", "12030.00", "W"
          ]
        )
        let LRI2 = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISLongRangeInterrogation,
          fields: [
            1, 0, 1_234_567_890, nil,
            "3530.00", "N", "12115.00", "W",
            "3400.00", "N", "12030.00", "W"
          ]
        )
        let data = LRI.data(using: .ascii)! + LRI2.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(3))
        guard let error = messages[2] as? MessageError else {
          fail("expected MessageError, got \(messages[2])")
          return
        }
        expect(error.type).to(equal(.unexpectedFormat))
      }
    }
  }
}
