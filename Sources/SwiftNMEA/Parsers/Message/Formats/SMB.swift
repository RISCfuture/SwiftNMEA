import Foundation

class SMBParser: MessageFormat {
  private static let coder = EscapedStringCoder()

  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETMessageBody
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1, optional: true)
    let identifier = try sentence.fields.int(at: 2, optional: true)
    let uniqueMessageNumber = try sentence.fields.int(at: 3)!
    let body = try sentence.fields.string(at: 4)!

    guard uniqueMessageNumber >= 0 else {
      throw sentence.fields.fieldError(type: .badValue, index: 3)
    }
    if let identifier, identifier < 0 || identifier > 9 {
      throw sentence.fields.fieldError(type: .badValue, index: 2)
    }

    // The sentence number may be null only when the total number of sentences
    // is "001"; for a single-sentence message we treat the implicit sentence
    // number as 1.
    let lastSentence = sentenceNumber ?? 1

    let recipient = Recipient(
      talker: sentence.talker,
      uniqueMessageNumber: UInt(uniqueMessageNumber),
      identifier: identifier.map(UInt.init)
    )
    let element = BufferElement(
      lastSentence: lastSentence,
      totalSentences: totalSentences,
      message: body
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        try makePayload(recipient: recipient, element: finishedElement)
      }
    } catch let error as SMBErrors {
      switch error {
        case .badMessage: throw sentence.fields.fieldError(type: .badEncoding, index: 4)
      }
    } catch let error as BufferErrors {
      switch error {
        case .missingRecipient:
          fatalError("Unexpected missingRecipient error")
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(
      talker: talker,
      format: format,
      includeIncomplete: includeIncomplete
    )

    return try flushed.map { recipient, element in
      do {
        let payload = try makePayload(recipient: recipient, element: element)
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as SMBErrors {
        switch error {
          case .badMessage:
            return MessageError(type: .badEncoding, fieldNumber: 4)
        }
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
    guard let body = element.body else { throw SMBErrors.badMessage }
    return .safetyNETMessageBody(
      body,
      uniqueMessageNumber: recipient.uniqueMessageNumber,
      identifier: recipient.identifier
    )
  }

  private enum SMBErrors: Error {
    case badMessage
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    let format = Format.safetyNETMessageBody
    let uniqueMessageNumber: UInt
    let identifier: UInt?
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // appended
    var message: String

    var body: String? { SMBParser.coder.decode(string: message) }

    mutating func append(payloadOnly other: Self) {
      message.append(contentsOf: other.message)
    }
  }
}
