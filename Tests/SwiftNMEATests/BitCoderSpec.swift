import Algorithms
import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class BitCoderSpec: AsyncSpec {
  override static func spec() {
    it("encodes a bitwise format") {
      var writer = BitWriter(size: 90)
      writer.write(0, bits: 2)  // 00
      writer.write(123, bits: 10)  // 0001111011
      writer.write(1234, bits: 12)  // 010011010010
      writer.write(155, bits: 12)  // 000010011011
      writer.write(1357, bits: 12)  // 010101001101
      writer.write(4095, bits: 12)  // 111111111111
      writer.write(0b100, bits: 3)  // 100
      writer.write(0, bits: 1)  // 0
      writer.write(16300, bits: 14)  // 11111110101100
      writer.write(1, bits: 1)  // 1
      writer.write(0, bits: 1)  // 0
      writer.write(0, bits: 2)  // 00
      writer.write(128, bits: 8)  // 10000000

      // 0000 0111    07
      // 1011 0100    B4
      // 1101 0010    D2
      // 0000 1001    09
      // 1011 0101    B5
      // 0100 1101    4D
      // 1111 1111    FF
      // 1111 1000    F8
      // 1111 1110    FE
      // 1011 0010    B2
      // 0010 0000    20
      // 00(00 00)    00

      let data = writer.data
      expect(data[0]).to(equal(0x07))
      expect(data[1]).to(equal(0xB4))
      expect(data[2]).to(equal(0xD2))
      expect(data[3]).to(equal(0x09))
      expect(data[4]).to(equal(0xB5))
      expect(data[5]).to(equal(0x4D))
      expect(data[6]).to(equal(0xFF))
      expect(data[7]).to(equal(0xF8))
      expect(data[8]).to(equal(0xFE))
      expect(data[9]).to(equal(0xB2))
      expect(data[10]).to(equal(0x20))
      expect(data[11]).to(equal(0x00))
    }

    it("decodes a bitwise format") {
      let data = Data([0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00])
      var reader = BitReader(data: data)

      expect(reader.read(bits: 2)).to(equal(0))
      expect(reader.read(bits: 10)).to(equal(123))
      expect(reader.read(bits: 12)).to(equal(1234))
      expect(reader.read(bits: 12)).to(equal(155))
      expect(reader.read(bits: 12)).to(equal(1357))
      expect(reader.read(bits: 12)).to(equal(4095))
      expect(reader.read(bits: 3)).to(equal(0b100))
      expect(reader.read(bits: 1)).to(equal(0))
      expect(reader.read(bits: 14)).to(equal(16300))
      expect(reader.read(bits: 1)).to(equal(1))
      expect(reader.read(bits: 1)).to(equal(0))
      expect(reader.read(bits: 2)).to(equal(0))
      expect(reader.read(bits: 8)).to(equal(128))
    }
  }
}
