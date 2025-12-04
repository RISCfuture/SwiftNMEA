@preconcurrency import RegexBuilder

actor ProprietaryParser {
  nonisolated(unsafe) private static let rx: Regex<(Substring, Substring, Substring, UInt8)> = {
    let manufacturerRef = Reference<Substring>()
    let dataRef = Reference<Substring>()
    let checksumRef = Reference<UInt8>()

    return Regex {
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
  }()

  func parse(sentence: String) throws -> ProprietaryResult? {
    guard let match = try Self.rx.wholeMatch(in: sentence) else { return nil }

    return .init(
      manufacturer: String(match.output.1),
      data: String(match.output.2),
      checksum: match.output.3
    )
  }

  struct ProprietaryResult {
    let manufacturer: String
    let data: String
    let checksum: UInt8
  }
}
