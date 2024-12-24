import Foundation

struct BitReader {
    private let data: Data
    private var offset = 0

    init(data: Data) {
        self.data = data
    }

    mutating func read<T: FixedWidthInteger>(bits: Int) -> T {
        precondition(bits > 0 && bits <= T.bitWidth, "Can't read > \(T.bitWidth) bits at a time")

        var value: T = 0
        for i in 0..<bits {
            let bitPosition = offset + i,
                byteOffset = bitPosition / 8,
                bitInByte = 7 - (bitPosition % 8),
                bit = (data[byteOffset] >> bitInByte) & 1
            value = (value << 1) | T(bit)
        }
        offset += bits
        return value
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
            let bitPosition = offset + (bits - 1 - i),
                byteOffset = bitPosition / 8,
                bitInByte = 7 - (bitPosition % 8),
                bit = (value >> i) & 1
            bytes[byteOffset] |= UInt8(bit << bitInByte)
        }
        offset += bits
    }
}
