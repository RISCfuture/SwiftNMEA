import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.5 ACA")
struct ACATests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
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

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
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
      Issue.record("expected .AISChannelAssignment, got \(payload)")
      return
    }

    #expect(sequenceNumber == 0)
    #expect(northeastCorner == .init(latitude: (37, 12.12), longitude: (-121, 12.35)))
    #expect(southwestCorner == .init(latitude: (36, 15.09), longitude: (-120, 11.11)))
    #expect(transitionZoneSize == .init(value: 2, unit: .nauticalMiles))
    #expect(channelA == 5)
    #expect(channelABandwidth == .byChannelNumber)
    #expect(channelB == 12)
    #expect(channelBBandwidth == .kHZ_12_5)
    #expect(txRxMode == .transmitB_receiveBoth)
    #expect(powerLevel == .high)
    #expect(source == .AISAssignmentSentence)
    #expect(inUse == true)
    #expect(inUseChangedActual == nil)
  }

  @Test("rejects an over-length sentence")
  func rejectsAnOverLengthSentence() async throws {
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

    #expect(messages.count == 1)
    guard let error = messages[0] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[0])")
      return
    }
    #expect(error.type == .sentenceTooLong)
  }
}
