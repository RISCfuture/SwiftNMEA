import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.99 SSD")
struct SSDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .automaticID,
      format: .AISShipStaticData,
      fields: [
        "N171MA", "@@@@@@@@@@@@@@@@@@@@",
        12, 23, nil, 0,
        0, "AI"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .AISShipStaticData(
        callsign,
        name,
        pointA,
        pointB,
        pointC,
        pointD,
        DTEAvailable,
        source
      ) = payload
    else {
      Issue.record("expected .AISShipStaticData, got \(payload)")
      return
    }

    #expect(callsign == .available("N171MA"))
    #expect(name == .unavailable)
    #expect(pointA == .available(.init(value: 12, unit: .meters)))
    #expect(pointB == .available(.init(value: 23, unit: .meters)))
    #expect(pointC == nil)
    #expect(pointD == .unavailable)
    #expect(DTEAvailable)
    #expect(source == .automaticID)
  }
}
