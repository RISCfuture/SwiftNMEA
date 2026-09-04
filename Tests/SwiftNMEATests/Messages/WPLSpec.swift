import Foundation
import NMEACommon
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.126 WPL` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .waypointLocation,
      fields: ["3530.00", "N", "12215.00", "W", "KOAK"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .waypointLocation(location, identifier) = payload else {
      Issue.record("expected .waypointLocation, got \(payload)")
      return
    }

    #expect(location.latitude == .init(value: 35.5, unit: .degrees))
    #expect(location.longitude == .init(value: -122.25, unit: .degrees))
    #expect(identifier == "KOAK")
  }
}
