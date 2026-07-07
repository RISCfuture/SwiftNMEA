import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.102 TLB")
struct TLBTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .targetLabels,
      fields: [1, "A", 2, "B", 3, ""]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .targetLabels([1: "A", 2: "B", 3: nil]))
  }

  @Test("throws an error for a duplicate target number")
  func throwsAnErrorForADuplicateTargetNumber() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .targetLabels,
      fields: [1, "A", 1, "B"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 2)
  }
}
