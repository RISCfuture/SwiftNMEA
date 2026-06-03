import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class AGLSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.9 AGL") {
      it("parses a single-sentence alert group list") {
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

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertGroupList(id, entries) = payload else {
          fail("expected .alertGroupList, got \(payload)")
          return
        }

        expect(id).to(equal(0))
        expect(entries).to(haveCount(2))

        // first entry is the group header alert (instance 0)
        expect(entries[0].systemFunctionID).to(equal("0001"))
        expect(entries[0].alert.manufacturerMnemonic).to(beNil())
        expect(entries[0].alert.identifier).to(equal(3001))
        expect(entries[0].alert.instance).to(equal(0))

        // second entry is a member alert with a manufacturer mnemonic
        expect(entries[1].systemFunctionID).to(equal("0002"))
        expect(entries[1].alert.manufacturerMnemonic).to(equal("NER"))
        expect(entries[1].alert.identifier).to(equal(3002))
        expect(entries[1].alert.instance).to(equal(5))
      }

      it("parses null SFI and null instance fields") {
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

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .alertGroupList(id, entries) = payload else {
          fail("expected .alertGroupList, got \(payload)")
          return
        }

        expect(id).to(equal(7))
        expect(entries).to(haveCount(2))
        expect(entries[0].systemFunctionID).to(beNil())
        expect(entries[0].alert.instance).to(equal(0))
        expect(entries[1].systemFunctionID).to(beNil())
        expect(entries[1].alert.instance).to(beNil())
      }

      it("assembles a multi-sentence message") {
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
          fail("expected an assembled Message, got \(messages)")
          return
        }
        guard case let .alertGroupList(id, entries) = payload else {
          fail("expected .alertGroupList, got \(payload)")
          return
        }

        expect(id).to(equal(3))
        expect(entries).to(haveCount(3))
        expect(entries[0].alert.identifier).to(equal(3001))
        expect(entries[1].alert.identifier).to(equal(3002))
        expect(entries[2].alert.identifier).to(equal(3003))
      }

      it("throws an error for a non-numeric alert identifier") {
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
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badNumericValue))
      }
    }
  }
}
