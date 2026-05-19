import Foundation

/// Encodes and decodes USO 8859-1 strings according to IEC 61162-1,
/// paragraph 7.1.4
final class EscapedStringCoder: Sendable {
  /**
   Decodes an escaped ASCII string into an ISO 8859-1 string.
  
   - Parameter string: The escaped ASCII string
   - Returns: The unescaped ISO 8859-1 string, or `nil` if the string contains
     non-ASCII characters.
   */
  func decode(string: String) -> String? {
    guard string.data(using: .ascii) != nil else { return nil }

    var decoded = Data()
    var iterator = string.makeIterator()
    decoded.reserveCapacity(string.count)

    while let char = iterator.next() {
      if char == "^",
        let firstHex = iterator.next(),
        let secondHex = iterator.next(),
        let byte = UInt8("\(firstHex)\(secondHex)", radix: 16)
      {
        decoded.append(byte)
      } else {
        decoded.append(char.asciiValue!)
      }
    }

    return String(data: decoded, encoding: .isoLatin1)
  }
}
