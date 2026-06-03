import Foundation

struct BitReader {
  private let data: Data
  private var offset = 0

  /// Number of bits not yet consumed from the underlying data.
  var remainingBits: Int { data.count * 8 - offset }

  init(data: Data) {
    self.data = data
  }

  /// Reads `bits` bits without advancing the read position.
  func peek<T: FixedWidthInteger>(bits: Int) -> T {
    var copy = self
    return copy.read(bits: bits)
  }

  mutating func read<T: FixedWidthInteger>(bits: Int) -> T {
    precondition(bits > 0 && bits <= T.bitWidth, "Can't read > \(T.bitWidth) bits at a time")
    precondition(bits <= remainingBits, "Can't read past the end of the data")

    // Accumulate into the unsigned magnitude type so a full-width signed read
    // does not overflow during the shift, then reinterpret the bits.
    var magnitude: T.Magnitude = 0
    for i in 0..<bits {
      let bitPosition = offset + i
      let byteOffset = data.startIndex + bitPosition / 8
      let bitInByte = 7 - (bitPosition % 8)
      let bit = (data[byteOffset] >> bitInByte) & 1
      magnitude = (magnitude << 1) | T.Magnitude(bit)
    }
    offset += bits

    var value = T(truncatingIfNeeded: magnitude)
    // AIS binary fields use two's-complement signed integers; sign-extend when
    // the field is narrower than the destination type so negative values decode
    // correctly instead of as large positives.
    if T.isSigned, bits < T.bitWidth, ((magnitude >> (bits - 1)) & 1) == 1 {
      value |= ~T(0) << bits
    }

    return value
  }

  /// Reads a single bit as a boolean flag. Avoids the signed-integer inference
  /// trap of `read(bits: 1) == 1`.
  mutating func readFlag() -> Bool {
    let bit: UInt8 = read(bits: 1)
    return bit == 1
  }
}

struct BitWriter {
  private var bytes: [UInt8]
  private var offset = 0

  var data: Data { .init(bytes) }

  init(size: Int) {
    bytes = .init(repeating: 0, count: size.ceilingDivide(UInt8.bitWidth))
  }

  mutating func write<T: FixedWidthInteger>(_ value: T, bits: Int) {
    precondition(bits > 0 && bits <= T.bitWidth, "Can't write > \(T.bitWidth) bits at a time")

    for i in 0..<bits {
      let bitPosition = offset + (bits - 1 - i)
      let byteOffset = bitPosition / 8
      let bitInByte = 7 - (bitPosition % 8)
      let bit = (value >> i) & 1
      bytes[byteOffset] |= UInt8(bit << bitInByte)
    }
    offset += bits
  }
}
