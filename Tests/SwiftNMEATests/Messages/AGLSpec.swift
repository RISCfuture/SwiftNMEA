import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.9 AGL")
struct AGLTests {
  @Test("parses a single-sentence alert group list")
  func parsesASingleSentenceAlertGroupList() async throws {
    let parser = SwiftNMEA()
    // total=1, sentence=1, messageID=0, then a header entry (instance 0)
    // and one member entry
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertGroupList,
      fields: [1, 1, 0, "0001", nil, 3001, 0, "0002", "NER", 3002, 5]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertGroupList(id, entries) = payload else {
      Issue.record("expected .alertGroupList, got \(payload)")
      return
    }

    #expect(id == 0)
    #expect(entries.count == 2)

    // first entry is the group header alert (instance 0)
    #expect(entries[0].systemFunctionID == "0001")
    #expect(entries[0].alert.manufacturerMnemonic == nil)
    #expect(entries[0].alert.identifier == 3001)
    #expect(entries[0].alert.instance == 0)

    // second entry is a member alert with a manufacturer mnemonic
    #expect(entries[1].systemFunctionID == "0002")
    #expect(entries[1].alert.manufacturerMnemonic == "NER")
    #expect(entries[1].alert.identifier == 3002)
    #expect(entries[1].alert.instance == 5)
  }

  @Test("parses null SFI and null instance fields")
  func parsesNullSFIAndNullInstanceFields() async throws {
    let parser = SwiftNMEA()
    // SFI null (alert from AGL source) and instance null (single instance)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertGroupList,
      fields: [1, 1, 7, nil, nil, 3001, 0, nil, nil, 3002, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .alertGroupList(id, entries) = payload else {
      Issue.record("expected .alertGroupList, got \(payload)")
      return
    }

    #expect(id == 7)
    #expect(entries.count == 2)
    #expect(entries[0].systemFunctionID == nil)
    #expect(entries[0].alert.instance == 0)
    #expect(entries[1].systemFunctionID == nil)
    #expect(entries[1].alert.instance == nil)
  }

  @Test("assembles a multi-sentence message")
  func assemblesAMultiSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let first = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertGroupList,
      fields: [2, 1, 3, "0001", nil, 3001, 0, "0002", nil, 3002, 1]
    )
    let second = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertGroupList,
      fields: [2, 2, 3, "0003", nil, 3003, 2]
    )
    let data = (first + second).data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    // the assembled message is emitted on receipt of the last sentence
    guard let payload = messages.compactMap({ ($0 as? Message)?.payload }).last else {
      Issue.record("expected an assembled Message, got \(messages)")
      return
    }
    guard case let .alertGroupList(id, entries) = payload else {
      Issue.record("expected .alertGroupList, got \(payload)")
      return
    }

    #expect(id == 3)
    #expect(entries.count == 3)
    #expect(entries[0].alert.identifier == 3001)
    #expect(entries[1].alert.identifier == 3002)
    #expect(entries[2].alert.identifier == 3003)
  }

  @Test("throws an error for a non-numeric alert identifier")
  func throwsAnErrorForANonNumericAlertIdentifier() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .alertGroupList,
      fields: [1, 1, 0, "0001", nil, "abc", 0]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badNumericValue)
  }
}
