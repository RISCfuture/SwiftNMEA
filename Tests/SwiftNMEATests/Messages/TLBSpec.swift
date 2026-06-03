import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class TLBSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.102 TLB") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .radar,
          format: .targetLabels,
          fields: [1, "A", 2, "B", 3, ""]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(equal(.targetLabels([1: "A", 2: "B", 3: nil])))
      }

      it("throws an error for a duplicate target number") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .radar,
          format: .targetLabels,
          fields: [1, "A", 1, "B"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.badValue))
        expect(error.fieldNumber).to(equal(2))
      }
    }
  }
}
