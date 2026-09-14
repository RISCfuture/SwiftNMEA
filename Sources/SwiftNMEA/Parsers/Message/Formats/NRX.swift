import Foundation

class NRXParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()
  private let decoder = EscapedStringCoder()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .NAVTEXMessage
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let lastSentence = try sentence.fields.int(at: 1)!
    let messageID = try sentence.fields.int(at: 2)!
    let messageCode = try sentence.fields.string(at: 3, optional: true)
    let frequency = try sentence.fields.enumeration(
      at: 4,
      ofType: NAVTEX.Frequency.self,
      optional: true
    )
    let time = try sentence.fields.datetime(ymdIndex: (8, 7, 6), hmsIndex: 5, optional: true)
    let totalChars = try sentence.fields.int(at: 9, optional: true)
    let badChars = try sentence.fields.int(at: 10, optional: true)
    let isValid = try sentence.fields.bool(at: 11, optional: true)
    let body = try sentence.fields.string(at: 12)!

    let recipient = Recipient(talker: sentence.talker, messageID: messageID)
    let element = BufferElement(
      lastSentence: lastSentence,
      totalSentences: totalSentences,
      messageCode: messageCode,
      frequency: frequency,
      time: time,
      totalCharacters: totalChars,
      badCharacters: badChars,
      isValid: isValid,
      message: body
    )

    let finishedElement: BufferElement?
    do {
      finishedElement = try buffer.add(element: element, for: recipient)
    } catch {
      switch error {
        case .missingRecipient:
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
    guard let finishedElement else { return nil }

    do {
      return try makePayload(recipient: recipient, element: finishedElement)
    } catch {
      switch error {
        case .missingValue(let index):
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: index)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
  {
    // complete messages are flushed upon receipt of the last message
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.map { recipient, element in
      message(recipient: recipient, element: element)
    }
  }

  private func message(recipient: Recipient, element: BufferElement) -> any Element {
    do {
      let payload = try makePayload(recipient: recipient, element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    } catch {
      switch error {
        case .missingValue(let index):
          return MessageError(type: .missingRequiredValue, fieldNumber: index)
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws(NRXErrors)
    -> Message.Payload
  {
    guard let message = decoder.decode(string: element.message) else {
      throw NRXErrors.missingValue(index: 12)
    }
    guard let frequency = element.frequency else {
      throw NRXErrors.missingValue(index: 4)
    }
    guard let time = element.time else {
      throw NRXErrors.missingValue(index: 5)
    }
    guard let totalChars = element.totalCharacters else {
      throw NRXErrors.missingValue(index: 9)
    }
    guard let badChars = element.badCharacters else {
      throw NRXErrors.missingValue(index: 10)
    }
    guard let isValid = element.isValid else {
      throw NRXErrors.missingValue(index: 11)
    }

    return .NAVTEXMessage(
      message,
      id: recipient.messageID,
      frequency: frequency,
      code: element.messageCode,
      time: time,
      totalCharacters: totalChars,
      badCharacters: badChars,
      isValid: isValid
    )
  }

  private enum NRXErrors: Error {
    case missingValue(index: Int)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    var format: Format = .NAVTEXMessage
    var messageID: Int
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // written once
    var messageCode: String?
    var frequency: NAVTEX.Frequency?
    var time: Date?
    var totalCharacters: Int?
    var badCharacters: Int?
    var isValid: Bool?

    // appended
    var message: String

    mutating func append(payloadOnly other: NRXParser.BufferElement) {
      messageCode ??= other.messageCode
      frequency ??= other.frequency
      time ??= other.time
      totalCharacters ??= other.totalCharacters
      badCharacters ??= other.badCharacters
      isValid ??= other.isValid

      message.append(other.message)
    }
  }
}
