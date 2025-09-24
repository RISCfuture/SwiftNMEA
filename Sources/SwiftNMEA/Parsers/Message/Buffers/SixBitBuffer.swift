import Foundation

private let coder = SixBitCoder()

protocol SixBitElement: SentenceCountingElement {
  var encapsulatedData: String { get set }
  var fillBits: Int { get set }

  mutating func append(otherFields other: Self)
}

extension SixBitElement {
  var data: Data? {
    coder.decode(encapsulatedData, fillBits: fillBits)
  }

  mutating func append(payloadOnly other: Self) {
    append(otherFields: other)

    encapsulatedData.append(other.encapsulatedData)
    fillBits = other.fillBits  // take last value
  }
}

struct SixBitBuffer<Recipient: BufferRecipient, Element: SixBitElement> {
  var buffer = SentenceCountingBuffer<Recipient, Element>()

  mutating func add(element: Element, optionallyFor recipient: Recipient?) throws -> (
    Recipient, Element
  )? {
    try buffer.add(element: element, optionallyFor: recipient)
  }

  mutating func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) -> [Recipient:
    Element]
  {
    buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
  }
}
