import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.89 SEL")
struct SELTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dataSelection,
      fields: ["POS", "GP0001", "HEA", "HE0001"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .dataSelection([.position: "GP0001", .heading: "HE0001"]))
  }

  @Test("parses a null source SFI")
  func parsesANullSourceSFI() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dataSelection,
      fields: ["SOG", "", "TIM", "TI0001"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .dataSelection([.speedCourseOverGround: nil, .time: "TI0001"]))
  }

  @Test("throws an error for an unknown data id")
  func throwsAnErrorForAnUnknownDataId()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dataSelection,
      fields: ["XXX", "GP0001"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
    #expect(error.fieldNumber == 0)
  }

  @Test("throws an error for a duplicate data id")
  func throwsAnErrorForADuplicateDataId()
    async throws
  {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .dataSelection,
      fields: ["POS", "GP0001", "POS", "GP0002"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 2)
  }
}
