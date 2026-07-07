import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.111 UID")
struct UIDTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .userIdentification,
      fields: ["HEPSLGN02376", "DB Los 23"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .userIdentification(code1: "HEPSLGN02376", code2: "DB Los 23"))
  }
}
