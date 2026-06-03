import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ALCSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.13 ALC") {
      describe(".parse") {
        it("parses a single-sentence cyclic alert list") {
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

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          expect(payload).to(
            equal(
              .cyclicAlertList(
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
          )
        }

        it("parses an empty cyclic alert list") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .integratedNavigation,
            format: .cyclicAlertList,
            fields: [1, 1, 0, 0]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let payload = (messages[1] as? Message)?.payload else {
            fail("expected Message, got \(messages[1])")
            return
          }
          expect(payload).to(equal(.cyclicAlertList([], sequentialID: 0)))
        }

        it("concatenates entries across multiple sentences") {
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

          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          expect(payload).to(
            equal(
              .cyclicAlertList(
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
          )
        }

        it("throws an error for an out-of-range revision counter") {
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
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.badValue))
          expect(error.fieldNumber).to(equal(7))
        }
      }
    }
  }
}
