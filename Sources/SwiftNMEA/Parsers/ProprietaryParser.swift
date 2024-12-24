@preconcurrency import RegexBuilder

actor ProprietaryParser {
    private let manufacturerRef = Reference<Substring>()
    private let dataRef = Reference<Substring>()
    private let checksumRef = Reference<UInt8>()

    private lazy var rx = Regex {
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
        } transform: { UInt8($0, radix: 16)! }
        Anchor.endOfSubject
    }

    func parse(sentence: String) throws -> ProprietaryResult? {
        guard let match = try rx.wholeMatch(in: sentence) else { return nil }
        let manufacturer = match[manufacturerRef],
            data = match[dataRef],
            checksum = match[checksumRef]

        return .init(manufacturer: String(manufacturer), data: String(data), checksum: checksum)
    }

    struct ProprietaryResult {
        let manufacturer: String
        let data: String
        let checksum: UInt8
    }
}
