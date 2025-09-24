@preconcurrency import RegexBuilder

actor QueryParser {
  private let fieldsRef = Reference<Substring>()
  private let checksumRef = Reference<UInt8>()

  private lazy var rx = Regex {
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

  func parse(sentence: String) throws -> QueryResult? {
    guard let match = try rx.wholeMatch(in: sentence) else { return nil }
    let fields = match[fieldsRef]
    let checksum = match[checksumRef]

    return .init(fields: fields, checksum: checksum)
  }

  struct QueryResult {
    let fields: Substring
    let checksum: UInt8
  }
}
