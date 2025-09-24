import Nimble
import Quick

@testable import SwiftNMEA

final class QuerySpec: AsyncSpec {
  override static func spec() {
    describe("Query") {
      describe("rawValue") {
        it("encodes a sentence") {
          let query = Query(
            requester: .GPS,
            recipient: .commDataReceiver,
            format: .MSKReceiverSignalStatus
          )
          expect(query.rawValue).to(equal("$GPCRQ,MSS*36\r\n"))
        }
      }

      describe("parsing") {
        it("parses a sentence from a STA8089FG") {
          let parser = SwiftNMEA()
          let sentence =
            "$PSTMPVRAW,235943.070,9000.00000,N,00000.00000,E,0,00,0.0,-6356752.31,M,0.0,M,nan,nan,nan*33\r\n"
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(1))
          guard let message = messages[0] as? ProprietarySentence else {
            fail("expected ProprietaryMessage, got \(messages[0])")
            return
          }

          expect(message.manufacturer).to(equal("STM"))
          expect(message.data).to(
            equal(
              "PVRAW,235943.070,9000.00000,N,00000.00000,E,0,00,0.0,-6356752.31,M,0.0,M,nan,nan,nan"
            )
          )
        }
      }
    }
  }
}
