import Nimble
import Quick

@testable import SwiftNMEA

final class ProprietarySentenceSpec: AsyncSpec {
  override static func spec() {
    describe("ProprietarySentence") {
      describe("rawValue") {
        it("encodes the sentence from the spec") {
          let sentence = ProprietarySentence(
            manufacturer: "SRD",
            data: "A003[470738][1224523]???RST47, 3809, A004"
          )
          expect(sentence.rawValue).to(
            equal("$PSRDA003[470738][1224523]???RST47, 3809, A004*47\r\n")
          )
        }
      }

      describe("parsing") {
        it("parses the sentence from the spec") {
          let sentence = try await ProprietarySentence(
            sentence: "$PSRDA003[470738][1224523]???RST47, 3809, A004*47"
          )!
          expect(sentence.manufacturer).to(equal("SRD"))
          expect(sentence.data).to(equal("A003[470738][1224523]???RST47, 3809, A004"))
        }
      }
    }
  }
}
