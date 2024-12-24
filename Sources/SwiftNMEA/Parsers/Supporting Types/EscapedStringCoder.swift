import Foundation

/// Encodes and decodes USO 8859-1 strings according to IEC 61162-1,
/// paragraph 7.1.4
final class EscapedStringCoder: Sendable {
    private let printableChars: ClosedRange<UInt8> = 0x20...0x7E
    private let reservedChars: [UInt8] = [0x0D, 0x0A, 0x24, 0x2A, 0x2C, 0x21, 0x5C, 0x5E, 0x7E, 0x7F]

    /**
     Encodes an ISO 8859-1 string into an ASCII string with escape characters.

     - Parameter string: The ISO 8859-1 string
     - Returns: The escaped ASCII string, or `nil` if the string contains
     non-ISO characters.
     */
    func encode(string: String) -> String? {
        guard let data = string.data(using: .isoLatin1) else { return nil }
        var encoded = ""
        encoded.reserveCapacity(string.count)

        for byte in data {
            if printableChars.contains(byte) && !reservedChars.contains(byte) {
                encoded.append(Character(UnicodeScalar(byte)))
            } else {
                encoded.append(String(format: "^%X", byte))
            }
        }

        return encoded
    }

    /**
     Decodes an escaped ASCII string into an ISO 8859-1 string.

     - Parameter string: The escaped ASCII string
     - Returns: The unescaped ISO 8859-1 string, or `nil` if the string contains
       non-ASCII characters.
     */
    func decode(string: String) -> String? {
        guard string.data(using: .ascii) != nil else { return nil }

        var decoded = Data(),
            iterator = string.makeIterator()
        decoded.reserveCapacity(string.count)

        while let char = iterator.next() {
            if char == "^",
               let firstHex = iterator.next(),
               let secondHex = iterator.next(),
               let byte = UInt8("\(firstHex)\(secondHex)", radix: 16) {
                decoded.append(byte)
            } else {
                decoded.append(char.asciiValue!)
            }
        }

        return String(data: decoded, encoding: .isoLatin1)
    }
}
