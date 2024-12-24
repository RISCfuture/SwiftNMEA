/**
 7.3.5 Query sentences

 Query sentences are intended to request approved sentences to be transmitted
 in a form of two-way communication. The use of query sentences implies that the
 listener shall have the capability of being a talker with its own bus.
 */
public struct Query: Sentence, Element, Sendable, Codable, Equatable {
    private static let parser = QueryParser()

    public var delimiter: Delimiter { .parametric }

    public let checksum: UInt8
    public let fields: Fields

    /// Talker identifier of requester
    public var requester: Talker { .init(rawValue: requesterStr)! }
    private var requesterStr: String { fields.address.sslice(to: 1) }

    /// Talker identifier for device from which data is being requested
    public var recipient: Talker { .init(rawValue: recipientStr)! }
    private var recipientStr: String { fields.address.sslice(from: 2, to: 3) }

    /// The requested format (see ``Message/Payload``).
    public var format: Format { .init(rawValue: formatStr)! }
    private var formatStr: String { fields[0]! }

    /// Creates a new instance from the given fields. The checksum is
    /// calculated automatically.
    public init(requester: Talker, recipient: Talker, format: Format) {
        fields = .init(data: "\(requester.rawValue)\(recipient.rawValue)Q,\(format.rawValue)")
        checksum = fields.checksum
    }

    public init?(sentence: String, ignoreChecksum: Bool = false) async throws {
        guard let result = try await Self.parser.parse(sentence: sentence) else { return nil }
        fields = .init(data: result.fields)
        checksum = result.checksum

        guard ignoreChecksum || checksumIsValid else {
            throw NMEAError(type: .wrongChecksum, line: rawValue, value: checksumString)
        }
    }
}
