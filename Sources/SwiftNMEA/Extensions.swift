import Algorithms
import Collections
import Foundation

extension Data {
  var hex: String {
    var string = ""
    for byte in self {
      string += String(format: "%02X", byte)
    }
    return string
  }

  init?(hex: String) {
    guard hex.count.isMultiple(of: 2) else { return nil }
    self.init(capacity: hex.count / 2)

    var index = hex.startIndex
    while index < hex.endIndex {
      let nextIndex = hex.index(index, offsetBy: 2)
      guard nextIndex <= hex.endIndex else { return nil }

      guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
      append(byte)

      index = nextIndex
    }
  }

  mutating func replace(with other: Data, from index: Data.Index) {
    if index + other.count > count {
      self.append(contentsOf: [UInt8](repeating: 0, count: (index + other.count) - count))
    }
    self.replaceSubrange(index..<(index + other.count), with: other)
  }
}

extension BitArray {
  var int32Value: UInt32 {  // LSB is index 1
    var value: UInt32 = 0
    for (i, bit) in prefix(32).enumerated() where bit {
      value |= (1 << i)
    }
    return value
  }

  init(int32Value: UInt32) {
    self.init(repeating: false, count: 32)
    for i in 0..<32 where int32Value & (1 << i) != 0 {
      self[i] = true
    }
  }
}

extension BinaryInteger {
  func ceilingDivide(_ rhs: Self) -> Self {
    let (quotient, remainder) = quotientAndRemainder(dividingBy: rhs)
    return quotient + (remainder > 0 ? 1 : 0)
  }
}

extension String.Encoding {
  static func iso8859(part: Int) -> Self? {
    let cfEncoding: CFStringEncodings
    switch part {
      case 1: return .isoLatin1
      case 2: return .isoLatin2
      case 3: cfEncoding = .isoLatin3
      case 4: cfEncoding = .isoLatin4
      case 5: cfEncoding = .isoLatinCyrillic
      case 6: cfEncoding = .isoLatinArabic
      case 7: cfEncoding = .isoLatinGreek
      case 8: cfEncoding = .isoLatinHebrew
      case 9: cfEncoding = .isoLatin9
      case 10: cfEncoding = .isoLatin10
      case 11: cfEncoding = .isoLatinThai
      case 13: cfEncoding = .isoLatin7
      case 14: cfEncoding = .isoLatin8
      case 15: cfEncoding = .isoLatin9
      case 16: cfEncoding = .isoLatin10
      default: return nil
    }

    let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
    return String.Encoding(rawValue: encoding)
  }
}

extension Range where Bound: Strideable {
  var succ: Self { lowerBound.advanced(by: 1)..<upperBound.advanced(by: 1) }
}

extension ClosedRange where Bound: Strideable {
  var succ: Self { lowerBound.advanced(by: 1)...upperBound.advanced(by: 1) }
}

extension PartialRangeFrom where Bound: Strideable {
  var succ: Self { lowerBound.advanced(by: 1)... }
}

extension PartialRangeUpTo where Bound: Strideable {
  var succ: Self { ..<upperBound.advanced(by: 1) }
}

extension PartialRangeThrough where Bound: Strideable {
  var succ: Self { ...upperBound.advanced(by: 1) }
}

infix operator ??= : AssignmentPrecedence
func ??= <T>(lhs: inout T?, rhs: @autoclosure () -> T?) {  // swiftlint:disable:this static_operator
  if lhs == nil { lhs = rhs() }
}
