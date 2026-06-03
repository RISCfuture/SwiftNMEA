import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ACASpec: AsyncSpec {
  override static func spec() {
    describe("8.3.5 ACA") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        // the “in-use changed” time field is null to keep the sentence within
        // the 82-character limit
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISChannelAssignment,
          fields: [
            0, 3712.12, "N", 12112.35, "W", 3615.09, "N", 12011.11, "W", 2, 5, 0, 12, 1, 2, 0, "C",
            1, nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .AISChannelAssignment(
            sequenceNumber,
            northeastCorner,
            southwestCorner,
            transitionZoneSize,
            channelA,
            channelABandwidth,
            channelB,
            channelBBandwidth,
            txRxMode,
            powerLevel,
            source,
            inUse,
            inUseChangedActual
          ) = payload
        else {
          fail("expected .AISChannelAssignment, got \(payload)")
          return
        }

        expect(sequenceNumber).to(equal(0))
        expect(northeastCorner).to(equal(.init(latitude: (37, 12.12), longitude: (-121, 12.35))))
        expect(southwestCorner).to(equal(.init(latitude: (36, 15.09), longitude: (-120, 11.11))))
        expect(transitionZoneSize).to(equal(.init(value: 2, unit: .nauticalMiles)))
        expect(channelA).to(equal(5))
        expect(channelABandwidth).to(equal(.byChannelNumber))
        expect(channelB).to(equal(12))
        expect(channelBBandwidth).to(equal(.kHZ_12_5))
        expect(txRxMode).to(equal(.transmitB_receiveBoth))
        expect(powerLevel).to(equal(.high))
        expect(source).to(equal(.AISAssignmentSentence))
        expect(inUse).to(equal(true))
        expect(inUseChangedActual).to(beNil())
      }

      it("rejects an over-length sentence") {
        let parser = SwiftNMEA()
        let inUseChanged = Date(timeIntervalSinceNow: -1000)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .commVHF,
          format: .AISChannelAssignment,
          fields: [
            0, 3712.12, "N", 12112.35, "W", 3615.09, "N", 12011.11, "W", 2, 5, 0, 12, 1, 2, 0, "C",
            1, hmsFractionFormatter.string(from: inUseChanged)
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(1))
        guard let error = messages[0] as? MessageError else {
          fail("expected MessageError, got \(messages[0])")
          return
        }
        expect(error.type).to(equal(.sentenceTooLong))
      }
    }
  }
}
