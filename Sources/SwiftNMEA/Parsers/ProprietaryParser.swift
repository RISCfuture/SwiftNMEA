import RegexBuilder

enum ProprietaryParser {
  private static let manufacturerRef = Reference<Substring>()
  private static let dataRef = Reference<Substring>()
  private static let checksumRef = Reference<UInt8>()

  private static let rx = LockedRegex(
    Regex {
      Anchor.startOfSubject
      "$P"
      Capture(as: manufacturerRef) {
        Repeat(.word, count: 3)
      }
      Capture(as: dataRef) {
        OneOrMore(.any)
      }
      "*"
      Capture(as: checksumRef) {
        Repeat(.hexDigit, count: 2)
      } transform: {
        UInt8($0, radix: 16)!
      }
      Anchor.endOfSubject
    }
  )

  static func parse(sentence: String) throws -> ProprietaryResult? {
    guard let match = try rx.wholeMatch(in: sentence) else { return nil }

    return .init(
      manufacturer: String(match[manufacturerRef]),
      data: String(match[dataRef]),
      checksum: match[checksumRef]
    )
  }

  struct ProprietaryResult {
    let manufacturer: String
    let data: String
    let checksum: UInt8
  }
}
