import RegexBuilder

enum ParametricParser {
  private static let delimiterRef = Reference<Delimiter>()
  private static let fieldsRef = Reference<Substring>()
  private static let checksumRef = Reference<UInt8>()

  private static let rx = LockedRegex(
    Regex {
      Anchor.startOfSubject
      Capture(as: delimiterRef) {
        ChoiceOf {
          "$"
          "!"
        }
      } transform: {
        .init(rawValue: $0.first!)!
      }
      Capture(as: fieldsRef) {
        Repeat(.word, count: 2)  // talker
        Repeat(.word, count: 3)  // format
        ","
        OneOrMore(.any)
      }
      "*"
      Capture(as: checksumRef) {
        Repeat(.hexDigit, count: 2)
      } transform: {
        .init($0, radix: 16)!
      }
      Anchor.endOfSubject
    }
  )

  static func parse(sentence: String) throws -> SentenceResult? {
    guard let match = try rx.wholeMatch(in: sentence) else { return nil }

    return .init(
      delimiter: match[delimiterRef],
      fields: match[fieldsRef],
      checksum: match[checksumRef]
    )
  }

  struct SentenceResult {
    let delimiter: Delimiter
    let fields: Substring
    let checksum: UInt8
  }
}
