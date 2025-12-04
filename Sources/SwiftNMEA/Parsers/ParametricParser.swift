@preconcurrency import RegexBuilder

actor ParametricParser {
  nonisolated(unsafe) private static let rx: Regex<(Substring, Delimiter, Substring, UInt8)> = {
    let delimiterRef = Reference<Delimiter>()
    let fieldsRef = Reference<Substring>()
    let checksumRef = Reference<UInt8>()

    return Regex {
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
  }()

  func parse(sentence: String) throws -> SentenceResult? {
    guard let match = try Self.rx.wholeMatch(in: sentence) else { return nil }

    return .init(
      delimiter: match.output.1,
      fields: match.output.2,
      checksum: match.output.3
    )
  }

  struct SentenceResult {
    let delimiter: Delimiter
    let fields: Substring
    let checksum: UInt8
  }
}
