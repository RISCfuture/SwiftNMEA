import RegexBuilder

enum QueryParser {
  private static let fieldsRef = Reference<Substring>()
  private static let checksumRef = Reference<UInt8>()

  private static let rx = LockedRegex(
    Regex {
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
  )

  static func parse(sentence: String) throws -> QueryResult? {
    guard let match = try rx.wholeMatch(in: sentence) else { return nil }

    return .init(fields: match[fieldsRef], checksum: match[checksumRef])
  }

  struct QueryResult {
    let fields: Substring
    let checksum: UInt8
  }
}
