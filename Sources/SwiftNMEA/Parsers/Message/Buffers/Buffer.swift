protocol BufferElement {
  var isComplete: Bool { get }

  mutating func append(_ other: Self) throws
}

protocol BufferRecipient: Hashable, Equatable {
  var talker: Talker { get }
  var format: Format { get }
}

protocol Buffer {
  associatedtype Recipient: BufferRecipient
  associatedtype Element: BufferElement

  var buffer: [Recipient: Element] { get set }

  mutating func add(element: Element, for recipient: Recipient) throws -> Element?
  mutating func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) -> [Recipient:
    Element]
}

extension Buffer {
  @discardableResult
  mutating func add(element: Element, for recipient: Recipient) throws -> Element? {
    if buffer.keys.contains(recipient) {
      try buffer[recipient]!.append(element)
    } else {
      buffer[recipient] = element
    }

    if buffer[recipient]!.isComplete {
      defer { buffer.removeValue(forKey: recipient) }
      return buffer[recipient]!
    }
    return nil
  }

  mutating func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) -> [Recipient:
    Element]
  {
    let flushed = buffer.filter { r, element in
      if let talker, r.talker != talker { return false }
      if let format, r.format != format { return false }
      if !includeIncomplete && !element.isComplete { return false }
      return true
    }

    defer {
      for recipient in flushed.keys { buffer.removeValue(forKey: recipient) }
    }

    return flushed
  }
}

enum BufferErrors: Error {
  case missingRecipient
  case wrongSentenceNumber
}
