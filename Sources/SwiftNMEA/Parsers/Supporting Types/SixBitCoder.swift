import Algorithms
import Foundation

/*
 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23
 |         8b0           |          8b1          |         8b2           |
 |        6b0      |      6b1        |      6b2        |      6b3        |

 vocabulary: byte = 8 bits, hexad = 6 bits, triplet = 3 bytes, hexword = 4 hexads
 */

final class SixBitCoder: Sendable {
    func encode(_ value: Data) -> (String, UInt8) {
        var result = "",
            bitBuffer: UInt = 0,
            bitCount = 0

        result.reserveCapacity(value.count * 8 / 6)

        for byte in value {
            // add the next 8 bits to the buffer
            bitBuffer = (bitBuffer << 8) | UInt(byte)
            bitCount += 8

            while bitCount >= 6 {
                // shift out 6 bits…
                let shift = bitCount - 6,
                    hexad = (bitBuffer >> shift) & 0b111111,
                    // … convert them to a character …
                    char = hexadToChar(UInt8(hexad))
                // … add that character to the result …
                result.unicodeScalars.append(char)
                // … and remove them from the buffer
                bitBuffer &= (1 << shift) - 1
                bitCount -= 6
            }
        }

        let fillBits = (bitCount == 0) ? 0 : (6 - bitCount)
        // if we have leftover bits in the buffer, do the same thing with the remainder
        // and record the number of fill bits we have to add to make a complete hexad
        if bitCount > 0 {
            let hexad = (bitBuffer << fillBits) & 0b111111,
                char = hexadToChar(UInt8(hexad))
            result.unicodeScalars.append(char)
        }

        return (result, UInt8(fillBits))
    }

    func encode(_ value: Data, chunkSize: Int) -> ([String], UInt8) {
        let (encoded, fillBits) = encode(value),
        chunks = encoded.chunks(ofCount: chunkSize).map { String($0) }

        return (chunks, fillBits)
    }

    func decode(_ value: String, fillBits: Int) -> Data? {
        let totalBits = value.count * 6 - fillBits
        var bitBuffer: UInt = 0,
            bitCount = 0,
            bitsProcessed = 0,
            result = Data()

        result.reserveCapacity(totalBits / 8)

        for char in value.unicodeScalars {
            let hexad = charToHexad(char)
            // add the hexad to the bit buffer
            bitBuffer = (bitBuffer << 6) | UInt(hexad)
            bitCount += 6

            // if the bit buffer has at least one byte
            while bitCount >= 8 && (bitsProcessed + 8) <= totalBits {
                // shift out the next byte
                let shift = bitCount - 8,
                    byte = UInt8((bitBuffer >> shift) & 0xFF)
                // add it to the result
                result.append(byte)
                // remove it from the bit buffer
                bitBuffer &= (1 << shift) - 1
                bitCount -= 8
                bitsProcessed += 8
            }
        }

        return result
    }

    private func hexadToChar(_ code: UInt8) -> UnicodeScalar {
        precondition(code < 0x40, "code not expressible in 6 bits")

        let ascii = code < 0b101000 ? code + 0b00110000 : code + 0b00111000
        return UnicodeScalar(ascii)
    }

    private func charToHexad(_ char: UnicodeScalar) -> UInt8 {
        var code = char.utf8.first! + 0b101000
        code += (code > 0b10000000) ? 0b100000 : 0b101000
        return code & 0b00111111
    }
}
