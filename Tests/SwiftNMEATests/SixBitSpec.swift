import Algorithms
import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SixBitSpec: AsyncSpec {
  override static func spec() {
    let encodedString = "1P000Oh1IT1svTP2r:43grwb05q4"
    let binaryData = """
      000001
      100000
      000000
      000000
      000000
      011111
      110000
      000001
      011001
      100100
      000001
      111011
      111110
      100100
      100000
      000010
      111010
      001010
      000100
      000011
      101111
      111010
      111111
      101010
      000000
      000101
      111001
      000100
      """
    let bytes =
      binaryData
      .replacing(.newlineSequence, with: "")
      .chunks(ofCount: 8)
      .map { UInt8($0, radix: 2)! }
    let data = Data(bytes)

    describe("encapsulation") {
      it("decodes the example string from the manual") {
        let coder = SixBitCoder()
        let decoded = coder.decode(encodedString, fillBits: 0)!
        expect(decoded).to(equal(data))
      }

      it("encodes the example string from the manual") {
        let coder = SixBitCoder()
        let (chunks, fillBits) = coder.encode(data, chunkSize: 48)
        expect(chunks).to(haveCount(1))
        expect(chunks[0]).to(equal(encodedString))
        expect(fillBits).to(equal(0))
      }
    }
  }
}
