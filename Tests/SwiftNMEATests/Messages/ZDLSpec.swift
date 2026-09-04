import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.131 ZDL` {
  @Test
  func `parses a sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .timeDistanceToVariablePoint,
      fields: ["010203.04", 12.3, "C"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .timeDistanceToVariablePoint(time, distance, type) = payload else {
      Issue.record("expected .timeDistanceToVariablePoint, got \(payload)")
      return
    }

    #expect(time == .seconds(3723) + .milliseconds(40))
    #expect(distance == .init(value: 12.3, unit: .nauticalMiles))
    #expect(type == .collision)
  }
}
