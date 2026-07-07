import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.13 ALC")
struct ALCTests {
  // MARK: - .parse

  @Test("parses a single-sentence cyclic alert list")
  func parsesASingleSentenceCyclicAlertList() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .cyclicAlertList,
      fields: [
        1, 1, 5, 2,
        nil, 3052, nil, 1,
        "XYZ", 10512, 4, 12
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload
        == .cyclicAlertList(
          [
            .init(
              identifier: .init(manufacturerMnemonic: nil, identifier: 3052, instance: nil),
              revisionCounter: 1
            ),
            .init(
              identifier: .init(manufacturerMnemonic: "XYZ", identifier: 10512, instance: 4),
              revisionCounter: 12
            )
          ],
          sequentialID: 5
        )
    )
  }

  @Test("parses an empty cyclic alert list")
  func parsesAnEmptyCyclicAlertList() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .cyclicAlertList,
      fields: [1, 1, 0, 0]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    #expect(payload == .cyclicAlertList([], sequentialID: 0))
  }

  @Test("concatenates entries across multiple sentences")
  func concatenatesEntriesAcrossMultipleSentences() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .cyclicAlertList,
        fields: [
          2, 1, 7, 1,
          nil, 3052, nil, 1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .integratedNavigation,
        format: .cyclicAlertList,
        fields: [
          2, 2, 7, 1,
          "ACM", 245, 2, 9
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let payload = try #require((messages[2] as? Message)?.payload)
    #expect(
      payload
        == .cyclicAlertList(
          [
            .init(
              identifier: .init(manufacturerMnemonic: nil, identifier: 3052, instance: nil),
              revisionCounter: 1
            ),
            .init(
              identifier: .init(manufacturerMnemonic: "ACM", identifier: 245, instance: 2),
              revisionCounter: 9
            )
          ],
          sequentialID: 7
        )
    )
  }

  @Test("throws an error for an out-of-range revision counter")
  func throwsAnErrorForAnOutOfRangeRevisionCounter() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .cyclicAlertList,
      fields: [
        1, 1, 5, 1,
        nil, 3052, nil, 0
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 7)
  }
}
