import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.14 ALF")
struct ALFTests {
  // MARK: - .parse

  // MARK: single-sentence message

  @Test("parses the spec example")
  func parsesTheSpecExample() async throws {
    let parser = SwiftNMEA()
    // $IIALF,1,1,0,124304.50,A,W,A,,3052,1,1,0,LOST TARGET
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .alert,
      fields: [1, 1, 0, "124304.50", "A", "W", "A", nil, 3052, 1, 1, 0, "LOST TARGET"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    guard
      case let .alert(
        identifier,
        sequentialMessageID: sequentialMessageID,
        time: time,
        category: category,
        priority: priority,
        state: state,
        revisionCounter: revisionCounter,
        escalationCounter: escalationCounter,
        title: title,
        description: description
      ) = payload
    else {
      Issue.record("expected .alert, got \(payload)")
      return
    }

    #expect(identifier.manufacturerMnemonic == nil)
    #expect(identifier.identifier == 3052)
    #expect(identifier.instance == 1)
    #expect(sequentialMessageID == 0)
    #expect(time != nil)
    #expect(category == .A)
    #expect(priority == .warning)
    #expect(state == .activeAcknowledged)
    #expect(revisionCounter == 1)
    #expect(escalationCounter == 0)
    #expect(title == "LOST TARGET")
    #expect(description == nil)
  }

  @Test("allows null category, priority, and state for a normal alert")
  func allowsNullCategoryPriorityAndStateForANormalAlert() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .alert,
      fields: [1, 1, nil, nil, nil, nil, "N", nil, 3052, nil, 1, 0, "NORMAL"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)

    guard
      case let .alert(
        identifier,
        sequentialMessageID: sequentialMessageID,
        time: time,
        category: category,
        priority: priority,
        state: state,
        revisionCounter: _,
        escalationCounter: _,
        title: title,
        description: description
      ) = payload
    else {
      Issue.record("expected .alert, got \(payload)")
      return
    }

    #expect(identifier.instance == nil)
    #expect(sequentialMessageID == nil)
    #expect(time == nil)
    #expect(category == nil)
    #expect(priority == nil)
    #expect(state == .normal)
    #expect(title == "NORMAL")
    #expect(description == nil)
  }

  // MARK: two-sentence message

  @Test("combines the title and description")
  func combinesTheTitleAndDescription() async throws {
    let parser = SwiftNMEA()
    // $IIALF,2,1,1,081950.10,B,A,S,XYZ,010512,1,2,0,HEADING LOST
    // $IIALF,2,2,1,,,,,XYZ,010512,1,2,0,NO SYSTEM HEADING AVAILABLE
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedInstrumentation,
        format: .alert,
        fields: [2, 1, 1, "081950.10", "B", "A", "S", "XYZ", 10512, 1, 2, 0, "HEADING LOST"]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedInstrumentation,
        format: .alert,
        fields: [
          2, 2, 1, nil, nil, nil, nil, "XYZ", 10512, 1, 2, 0,
          "NO SYSTEM HEADING AVAILABLE"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)

    guard
      case let .alert(
        identifier,
        sequentialMessageID: _,
        time: _,
        category: category,
        priority: priority,
        state: state,
        revisionCounter: _,
        escalationCounter: _,
        title: title,
        description: description
      ) = payload
    else {
      Issue.record("expected .alert, got \(payload)")
      return
    }

    #expect(identifier.manufacturerMnemonic == "XYZ")
    #expect(identifier.identifier == 10512)
    #expect(category == .B)
    #expect(priority == .alarm)
    #expect(state == .activeSilenced)
    #expect(title == "HEADING LOST")
    #expect(description == "NO SYSTEM HEADING AVAILABLE")
  }

  @Test("throws for a negative alert identifier")
  func throwsForANegativeAlertIdentifier() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .alert,
      fields: [1, 1, 0, "124304.50", "A", "W", "A", nil, -5, 1, 1, 0, "LOST TARGET"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 8)
  }

  @Test("throws for an unknown alert state")
  func throwsForAnUnknownAlertState() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .alert,
      fields: [1, 1, 0, "124304.50", "A", "W", "Z", nil, 3052, 1, 1, 0, "LOST TARGET"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }

  // MARK: - .flush

  @Test("flushes an incomplete multi-sentence message")
  func flushesAnIncompleteMultiSentenceMessage() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .alert,
      fields: [2, 1, 1, "081950.10", "B", "A", "S", "XYZ", 10512, 1, 2, 0, "HEADING LOST"]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)
    let payload = try #require((messages[0] as? Message)?.payload)

    guard
      case let .alert(_, _, _, _, _, _, _, _, title: title, description: description) =
        payload
    else {
      Issue.record("expected .alert, got \(payload)")
      return
    }
    #expect(title == "HEADING LOST")
    #expect(description == nil)
  }
}
