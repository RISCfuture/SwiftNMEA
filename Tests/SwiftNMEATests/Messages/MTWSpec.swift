import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.67 MTW")
struct MTWTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .commDataReceiver,
      format: .waterTemperature,
      fields: [5.0, "C"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    #expect(payload == .waterTemperature(.init(value: 5, unit: .celsius)))
  }
}
