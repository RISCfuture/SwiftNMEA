import Foundation

/// A class that buffers streaming data and parses detected NMEA ``Sentence``s
/// and ``Message``s.
public class SwiftNMEA {
    private static let lineSeparator: [UInt8] = [0x0D, 0x0A] // CRLF

    /// The subtypes of ``Element`` that will not be ignored. If empty, no types
    /// are ignored.
    public var typeFilter: [any Element.Type]

    /// The talkers that will not be ignored. If empty, no talkers are ignored.
    /// Because ``ProprietarySentence``s and ``MessageError``s do not have
    /// talkers, they will be filtered out if this filter is non-empty.
    public var talkerFilter: Set<Talker>

    /// The formats that will not be ignored. If empty, no formats are ignored.
    /// Because ``ProprietarySentence``s and ``MessageError``s do not have
    /// formats, they will be filtered out if this filter is non-empty.
    public var formatFilter: Set<Format>

    private let messageParser = MessageParser()
    private var buffer = Data()

    private var shouldIncludeQueries: Bool { typeFilter.isEmpty || typeFilter.contains { $0 == Query.self } }
    private var shouldIncludeParametric: Bool { typeFilter.isEmpty || typeFilter.contains { $0 == ParametricSentence.self } }
    private var shouldIncludeProprietary: Bool { typeFilter.isEmpty || typeFilter.contains { $0 == ProprietarySentence.self } }
    private var shouldIncludeMessages: Bool { typeFilter.isEmpty || typeFilter.contains { $0 == Message.self } }

    /**
     Creates a new parser with the given filter settings.

     - Parameter typeFilter: See ``typeFilter``
     - Parameter talkerFilter: See ``talkerFilter``
     - Parameter formatFilter: See ``formatFilter``
     */
    public init(typeFilter: [any Element.Type] = [], talkerFilter: [Talker] = [], formatFilter: [Format] = []) {
        self.typeFilter = typeFilter
        self.talkerFilter = .init(talkerFilter)
        self.formatFilter = .init(formatFilter)
    }

    /**
     Buffers data and returns any detected NMEA sentences and messages in the
     data stream.

     This method is intended to be used with a stream of data that can be
     received intermittently. It should be called any time new data is received.
     Each time new data is received, completed sentences (delimited by `\r\n`
     characters) are extracted from the data stream, parsed, and returned as
     ``Sentence`` records. If one or more Sentences can be parsed into a
     ``Message``, that Message instance is also returned.

     Sentences can be of type ``ParametricSentence``, ``Query``, or
     ``ProprietarySentence``. ParametricSentences will also be parsed into
     Messages. Some messages are parsed from multiple sentences. In this case,
     the consolidated message will not be returned until the last sentence has
     been parsed.

     Some messages are "open-ended", in other words, they are constructed from
     multiple sentences, but without any indication of which sentence is the
     last. The only way to receive this messages is to call
     ``flush(talker:format:includeIncomplete:)``. You will need to detect when
     such a sentence group has completed using other means, and call `flush` at
     that point. Typically these sentence groups are transmitted contiguously,
     so you could, for example, call `flush` after a period of time has elapsed
     with no new sentences from that talker.

     - Parameter data: The data stream to parse.
     - Parameter ignoreChecksums: If `true`, does not abort parsing if checksum
     validation fails.
     - Returns: The parsed sentences and messages.
     */
    public func parse(data: Data, ignoreChecksums: Bool = false) async throws -> [any Element] {
        buffer.append(data)
        var lines = [String]()
        while let line = try extractFirstSentence() {
            lines.append(line)
        }
        return try await parseSentences(from: lines, ignoreChecksums: ignoreChecksums)
    }

    /**
     Returns any multi-sentence ``Message``s that have not yet been flushed from
     their buffers.

     Some messages are constructed from multiple sentences. These messages are
     buffered and not returned by ``parse(data:ignoreChecksums:)`` until the
     last sentence has been parsed.

     Some messages are "open-ended", in other words, they are constructed from
     multiple ``ParametricSentence``s, but without any indication of which
     sentence is the last. The only way to receive this messages is to call this
     method; they will never be returned by `parse`. You will need to detect when
     such a sentence group has completed using other means, and call this method
     at that point. Typically these sentence groups are transmitted
     contiguously, so you could, for example, call this method after a period of
     time has elapsed with no new sentences from that talker.

     By default, all known-completed messages are returned and removed from the
     buffer. You have the option of limiting the flush to only messages from a
     particular talker and format. You also have the option of including
     incomplete messages. This is the only way to receive open-ended messages.
     It's also a way of retrieving what useful data is available from an
     incomplete transmission.

     - Parameter talker: Only flush messages from this talker.
     - Parameter format: Only flush messages with this format.
     - Parameter includeIncomplete: Include both incomplete and open-ended
       messages.
     - Returns: ``Message``s and ``MessageError``s flushed and removed from the buffer.
     */
    public func flush(talker: Talker? = nil, format: Format? = nil, includeIncomplete: Bool = false) async throws -> [any Element] {
        try await messageParser.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    }

    private func extractFirstSentence() throws -> String? {
        guard let separatorRange = buffer.firstRange(of: Self.lineSeparator) else { return nil }
        let sentenceRange = buffer.startIndex..<separatorRange.lowerBound,
            sentenceAndSeparatorRange = buffer.startIndex..<separatorRange.upperBound,
            data = buffer.subdata(in: sentenceRange)
        buffer.removeSubrange(sentenceAndSeparatorRange)

        if let sentence = String(data: data, encoding: .ascii) {
            return sentence
        }
        throw NMEAError(type: .badEncoding)
    }

    private func parseSentences(from lines: [String], ignoreChecksums: Bool = false) async throws -> [any Element] {
        var messages: [any Element] = []
        for line in lines {
            do {
                if let query = try await Query(sentence: line, ignoreChecksum: ignoreChecksums) {
                    // we have to parse queries unconditionally because otherwise they'll be caught by ParametricParser
                    addIfFilterMatches(query, to: &messages)
                }
                else if shouldIncludeProprietary,
                        let proprietary = try await ProprietarySentence(sentence: line, ignoreChecksum: ignoreChecksums) {
                    addIfFilterMatches(proprietary, to: &messages)
                }
                else if shouldIncludeParametric || shouldIncludeMessages,
                        let sentence = try await ParametricSentence(sentence: line, ignoreChecksum: ignoreChecksums) {
                    addIfFilterMatches(sentence, to: &messages)
                    if shouldIncludeMessages,
                       let message = try await messageParser.parse(sentence: sentence) {
                        addIfFilterMatches(message, to: &messages)
                    }
                }
            } catch let error as NMEAError {
                messages.append(MessageError(from: error))
                continue
            }
        }

        return messages
    }

    private func typeFilterMatches(element: any Element) -> Bool {
        guard !typeFilter.isEmpty else { return true }

        if element is MessageError {
            return true
        }
        if element is Query {
            return typeFilter.contains { $0 == Query.self }
        }
        if element is ParametricSentence {
            return typeFilter.contains { $0 == ParametricSentence.self }
        }
        if element is Message {
            return typeFilter.contains { $0 == Message.self }
        }
        if element is ProprietarySentence {
            return typeFilter.contains { $0 == ProprietarySentence.self }
        }
        fatalError("Unexpected Element \(element)")
    }

    private func talkerFilterMatches(element: any Element) -> Bool {
        guard !talkerFilter.isEmpty else { return true }

        if let query = element as? Query {
            return talkerFilter.contains(query.requester)
        }
        if let sentence = element as? ParametricSentence {
            return talkerFilter.contains(sentence.talker)
        }
        if let message = element as? Message {
            return talkerFilter.contains(message.talker)
        }
        return false
    }

    private func formatFilterMatches(element: any Element) -> Bool {
        guard !formatFilter.isEmpty else { return true }

        if let query = element as? Query {
            return formatFilter.contains(query.format)
        }
        if let sentence = element as? ParametricSentence {
            return formatFilter.contains(sentence.format)
        }
        if let message = element as? Message {
            return formatFilter.contains(message.format)
        }
        return false
    }

    private func addIfFilterMatches(_ element: any Element, to messages: inout [any Element]) {
        if typeFilterMatches(element: element),
           talkerFilterMatches(element: element),
           formatFilterMatches(element: element) {
            messages.append(element)
        }
    }
}
