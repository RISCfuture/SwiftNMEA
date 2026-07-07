import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.87 RSD")
struct RSDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .radarSystemData,
      fields: [
        1.2, 23.4, 3.4, 45.6,
        6.5, 65.4, 4.3, 43.2,
        123.4, 234.5,
        40.0, "N", "N"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .radarSystemData(
        origin1,
        VRM1,
        EBL1,
        origin2,
        VRM2,
        EBL2,
        cursor,
        rangeScale,
        rotation
      ) = payload
    else {
      Issue.record("expected .radarSystemData, got \(payload)")
      return
    }

    #expect(origin1.bearing.angle == .init(value: 23.4, unit: .degrees))
    #expect(origin1.bearing.reference == .relative)
    #expect(origin1.range == .init(value: 1.2, unit: .nauticalMiles))
    #expect(VRM1 == .init(value: 3.4, unit: .nauticalMiles))
    #expect(EBL1.angle == .init(value: 45.6, unit: .degrees))
    #expect(EBL1.reference == .relative)

    #expect(origin2.bearing.angle == .init(value: 65.4, unit: .degrees))
    #expect(origin2.bearing.reference == .relative)
    #expect(origin2.range == .init(value: 6.5, unit: .nauticalMiles))
    #expect(VRM2 == .init(value: 4.3, unit: .nauticalMiles))
    #expect(EBL2.angle == .init(value: 43.2, unit: .degrees))
    #expect(EBL2.reference == .relative)

    #expect(rangeScale == .init(value: 40, unit: .nauticalMiles))
    #expect(rotation == .northUp)

    #expect(cursor.bearing.angle == .init(value: 234.5, unit: .degrees))
    #expect(cursor.bearing.reference == .relative)
    #expect(cursor.range == .init(value: 123.4, unit: .nauticalMiles))
  }
}
