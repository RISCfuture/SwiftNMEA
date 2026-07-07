import Algorithms
import Foundation
import Testing

@testable import SwiftNMEA

@Suite("encapsulation")
struct SixBitTests {
  private static let encodedString = "1P000Oh1IT1svTP2r:43grwb05q4"
  private static let data: Data = {
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
    return Data(bytes)
  }()

  @Test("decodes the example string from the manual")
  func decodesTheExampleString() throws {
    let coder = SixBitCoder()
    let decoded = coder.decode(Self.encodedString, fillBits: 0)!
    #expect(decoded == Self.data)
  }

  @Test("encodes the example string from the manual")
  func encodesTheExampleString() throws {
    let coder = SixBitCoder()
    let (chunks, fillBits) = coder.encode(Self.data, chunkSize: 48)
    #expect(chunks.count == 1)
    #expect(chunks[0] == Self.encodedString)
    #expect(fillBits == 0)
  }

  @Test("rejects characters outside the six-bit alphabet")
  func rejectsCharactersOutsideTheSixBitAlphabet() throws {
    let coder = SixBitCoder()
    // 'X' (0x58) and 'z' (0x7A) fall in the gaps between the armoring ranges
    #expect(coder.decode("X", fillBits: 0) == nil)
    #expect(coder.decode("1P00z", fillBits: 0) == nil)
  }
}
