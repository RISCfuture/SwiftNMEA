import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class UIDSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.88 UID") {
      it("parses the example from the spec") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GPS,
          format: .userIdentification,
          fields: ["HEPSLGN02376", "DB Los 23"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(equal(.userIdentification(code1: "HEPSLGN02376", code2: "DB Los 23")))
      }
    }
  }
}
