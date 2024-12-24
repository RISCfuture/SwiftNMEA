/**
 Indicates a sentence that is a status report of current settings or a
 configuration command changing settings.
 */
public enum SentenceType: Character, Sendable, Codable, Equatable {

    /// Sentence is a status report of current settings (use for a reply to
    /// a query).
    case reply = "R"

    /// Sentence is a configuration command to change settings. A sentence
    /// without “C” is not a command.
    case command = "C"
}

/**
 Reasons for a `NAK` sentence.

 - SeeAlso: ``Message/Payload-swift.enum/negativeAcknowledgement(talker:format:uniqueID:reasonCode:reason:)``
 */
public enum NAKReason: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = Int

    /// Query functionality not supported
    case queryNotSupported

    /// Sentence formatter not supported
    case formatNotSupported

    /// Sentence formatter supported, but not enabled
    case formatDisabled

    /// Sentence formatter supported and enabled, but temporarily
    /// unavailable (for instance, data field problem, unit in initialize
    /// state, or in diagnostic state, etc.)
    case formatUnavailable

    /// Sentence formatter supported, but query for this sentence formatter
    /// is not supported
    case formatQueryNotSupported

    /// Access denied, for sentence formatter requested
    case accessDenied

    /// Sentence not accepted due to bad checksum
    case badChecksum

    /// Sentence not accepted due to listener processing issue
    case processingIssue

    /// Cannot perform the requested operation
    case unable

    /// Cannot fulfil request or command because of a problem with a data field in the sentence
    case badDataField

    /// Other reason as described in `reasonText` data field
    case other

    /// Code defined by equipment standards
    case custom(_ code: Int)

    public var rawValue: Int {
        switch self {
            case .queryNotSupported: 0
            case .formatNotSupported: 1
            case .formatDisabled: 2
            case .formatUnavailable: 3
            case .formatQueryNotSupported: 4
            case .accessDenied: 5
            case .badChecksum: 6
            case .processingIssue: 7
            case .unable: 10
            case .badDataField: 11
            case .other: 49
            case let .custom(code): code
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
            case 0: self = .queryNotSupported
            case 1: self = .formatNotSupported
            case 2: self = .formatDisabled
            case 3: self = .formatUnavailable
            case 4: self = .formatQueryNotSupported
            case 5: self = .accessDenied
            case 6: self = .badChecksum
            case 7: self = .processingIssue
            case 10: self = .unable
            case 11: self = .badDataField
            case 49: self = .other
            default: self = .custom(rawValue)
        }
    }
}
