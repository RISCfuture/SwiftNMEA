import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.88 RTE")
struct RTETests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {

    // MARK: Setup

    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .route,
        fields: [
          2, 1, "c", "KSQLKDWA",
          "KSQL", "DMDWW", "VPMID", "OAK30"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .route,
        fields: [
          2, 2, nil, nil,
          "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .route,
        fields: [
          1, 1, "w", "KSQLKOAK",
          "DMDWW", "VPMID", "OAKSLM", "KOAK"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)

    // MARK: Message 0

    guard let payload = (messages[2] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[2])")
      return
    }
    guard case let .route(mode, identifier, waypoints) = payload else {
      Issue.record("expected .route, got \(payload)")
      return
    }
    #expect(mode == .complete)
    #expect(identifier == "KSQLKDWA")
    #expect(
      waypoints == [
        "KSQL", "DMDWW", "VPMID", "OAK30",
        "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"
      ]
    )

    // MARK: Message 1

    guard let payload = (messages[4] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[4])")
      return
    }
    guard case let .route(mode, identifier, waypoints) = payload else {
      Issue.record("expected .route, got \(payload)")
      return
    }
    #expect(mode == .working)
    #expect(identifier == "KSQLKOAK")
    #expect(waypoints == ["DMDWW", "VPMID", "OAKSLM", "KOAK"])
  }

  @Test("throws an error for an invalid senence number")
  func throwsAnErrorForAnInvalidSenenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .route,
        fields: [
          2, 1, "c", "KSQLKDWA",
          "KSQL", "DMDWW", "VPMID", "OAK30"
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .route,
        fields: [
          2, 3, nil, nil,
          "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .route,
      fields: [
        2, 1, "c", "KSQLKDWA",
        "KSQL", "DMDWW", "VPMID", "OAK30"
      ]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    guard let message = messages[0] as? Message else {
      Issue.record("expected Message, got \(messages[0])")
      return
    }
    guard case let .route(mode, identifier, waypoints) = message.payload else {
      Issue.record("expected .route, got \(message)")
      return
    }
    #expect(mode == .complete)
    #expect(identifier == "KSQLKDWA")
    #expect(waypoints == ["KSQL", "DMDWW", "VPMID", "OAK30"])
  }
}
