@preconcurrency import RegexBuilder

actor QueryParser {
  nonisolated(unsafe) private static let rx: Regex<(Substring, Substring, UInt8)> = {
    let fieldsRef = Reference<Substring>()
    let checksumRef = Reference<UInt8>()

    return Regex {
      Anchor.startOfSubject
      "$"
      Capture(as: fieldsRef) {
        Repeat(.word, count: 2)  // requester
        Repeat(.word, count: 2)  // recipient
        "Q,"
        Repeat(.word, count: 3)  // format
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

  func parse(sentence: String) throws -> QueryResult? {
    guard let match = try Self.rx.wholeMatch(in: sentence) else { return nil }

    return .init(fields: match.output.1, checksum: match.output.2)
  }

  struct QueryResult {
    let fields: Substring
    let checksum: UInt8
  }
}
