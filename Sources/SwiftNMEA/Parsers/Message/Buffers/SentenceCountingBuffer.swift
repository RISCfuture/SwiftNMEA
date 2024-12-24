protocol SentenceCountingElement: BufferElement {
    var lastSentence: Int { get }
    var totalSentences: Int { get }
    var allSentences: Set<Int> { get set }

    mutating func append(payloadOnly other: Self)
}

extension SentenceCountingElement {
    private var allExpectedSentences: Set<Int> { .init(1...totalSentences) }

    var isComplete: Bool {
        totalSentences == 1 || allSentences == allExpectedSentences
    }

    mutating func append(_ other: Self) throws {
        guard !allSentences.contains(other.lastSentence),
              lastSentence != other.lastSentence,
              other.lastSentence >= 1,
                other.lastSentence <= totalSentences else {
            throw BufferErrors.wrongSentenceNumber
        }
        allSentences.insert(lastSentence) // should be done at init but we'll do it here to preserve auto-generated inits
        allSentences.insert(other.lastSentence)

        append(payloadOnly: other)
    }
}

struct SentenceCountingBuffer<Recipient: BufferRecipient, Element: SentenceCountingElement>: Buffer {
    var buffer = [Recipient: Element]()
    var lastRecipient: Recipient?

    mutating func add(element: Element, optionallyFor recipient: Recipient?) throws -> (Recipient, Element)? {
        if let recipient {
            if let message = try add(element: element, for: recipient) {
                lastRecipient = nil
                return (recipient, message)
            }
            lastRecipient = recipient
            return nil
        }
        if let recipient = lastRecipient {
            if let message = try add(element: element, for: recipient) {
                lastRecipient = nil
                return (recipient, message)
            }
            return nil
        }
        throw BufferErrors.missingRecipient
    }
}
