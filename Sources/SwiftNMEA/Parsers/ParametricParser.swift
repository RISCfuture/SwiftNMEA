@preconcurrency import RegexBuilder

actor ParametricParser {
    private let delimiterRef = Reference<Delimiter>()
    private let fieldsRef = Reference<Substring>()
    private let checksumRef = Reference<UInt8>()

    private lazy var rx = Regex {
        Anchor.startOfSubject
        Capture(as: delimiterRef) {
            ChoiceOf {
                "$"
                "!"
            }
        } transform: { .init(rawValue: $0.first!)! }
        Capture(as: fieldsRef) {
            Repeat(.word, count: 2) // talker
            Repeat(.word, count: 3) // format
            ","
            OneOrMore(.any)
        }
        "*"
        Capture(as: checksumRef) {
            Repeat(.hexDigit, count: 2)
        } transform: { .init($0, radix: 16)! }
        Anchor.endOfSubject
    }

    func parse(sentence: String) throws -> SentenceResult? {
        guard let match = try rx.wholeMatch(in: sentence) else { return nil }
        let delimiter = match[delimiterRef],
            fields = match[fieldsRef],
            checksum = match[checksumRef]

        return .init(delimiter: delimiter,
                     fields: fields,
                     checksum: checksum)
    }

    struct SentenceResult {
        let delimiter: Delimiter
        let fields: Substring
        let checksum: UInt8
    }
}
