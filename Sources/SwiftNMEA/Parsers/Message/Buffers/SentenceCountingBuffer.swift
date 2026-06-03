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
    // `lastSentence` for the stored element is recorded lazily on first append.
    var received = allSentences
    received.insert(lastSentence)
    let highestSoFar = received.max() ?? 0

    // Require a consistent sentence count and strictly increasing sentence
    // numbers so payload parts always concatenate in ascending order. An
    // out-of-order or duplicate sentence (which would otherwise be appended in
    // the wrong place, silently corrupting the message) or a mismatched total
    // is rejected. Gaps are tolerated: the message simply never completes and is
    // surfaced through `flush`.
    guard other.totalSentences == totalSentences,
      other.lastSentence > highestSoFar,
      other.lastSentence <= totalSentences
    else {
      throw BufferErrors.wrongSentenceNumber
    }

    allSentences.insert(lastSentence)
    allSentences.insert(other.lastSentence)

    append(payloadOnly: other)
  }
}

struct SentenceCountingBuffer<Recipient: BufferRecipient, Element: SentenceCountingElement>: Buffer
{
  var buffer = [Recipient: Element]()
  var lastRecipient: Recipient?

  mutating func add(element: Element, optionallyFor recipient: Recipient?) throws -> (
    Recipient, Element
  )? {
    // reject out-of-range counts before they reach `1...totalSentences`, which
    // would trap on a non-positive total
    guard element.totalSentences >= 1,
      element.lastSentence >= 1,
      element.lastSentence <= element.totalSentences
    else {
      throw BufferErrors.wrongSentenceNumber
    }

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
