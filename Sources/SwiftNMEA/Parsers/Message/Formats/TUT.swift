import Foundation
import NMEACommon

class TUTParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .multiLanguageText
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let source = try sentence.fields.enumeration(at: 0, ofType: Talker.self)!
    let totalSentences = try sentence.fields.hex(at: 1, width: 2)!
    let sentenceNumber = try sentence.fields.hex(at: 2, width: 2)!
    let identifier = try sentence.fields.int(at: 3, optional: true)
    let translationCode = try sentence.fields.string(at: 4)!
    let body = try sentence.fields.string(at: 5)!

    let recipient = identifier.map { identifier in
      Recipient(
        sentence: sentence,
        source: source,
        identifier: identifier
      )
    }
    let element = BufferElement(
      lastSentence: Int(sentenceNumber),
      totalSentences: Int(totalSentences),
      translationCode: translationCode,
      body: body
    )

    let finished: (Recipient, BufferElement)?
    do {
      finished = try buffer.add(element: element, optionallyFor: recipient)
    } catch {
      switch error {
        case .missingRecipient:
          fatalError("Unexpected missingRecipient error")
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
    guard let finished else { return nil }

    do {
      return try makePayload(recipient: finished.0, element: finished.1)
    } catch {
      switch error {
        case .badData: throw sentence.fields.fieldError(type: .badValue, index: 5)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
  {
    if !includeIncomplete {
      return []
    }  // complete messages are flushed upon receipt of the last message

    let flushed = buffer.flush(
      talker: talker,
      format: format,
      includeIncomplete: includeIncomplete
    )
    return flushed.map { recipient, element in
      message(for: recipient, element: element)
    }
  }

  private func message(for recipient: Recipient, element: BufferElement) -> any Element {
    do {
      let payload = try makePayload(recipient: recipient, element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    } catch {
      switch error {
        case .badData:
          return MessageError(type: .badValue, fieldNumber: 5)
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws(TUTErrors)
    -> Message.Payload
  {
    guard let data = element.data else { throw TUTErrors.badData }
    return .multiLanguageText(
      source: recipient.source,
      text: element.text,
      data: data,
      translationCode: element.translationCode
    )
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    let format = Format.multiLanguageText
    let source: Talker
    let identifier: Int

    init(
      sentence: ParametricSentence,
      source: Talker,
      identifier: Int
    ) {
      talker = sentence.talker
      self.source = source
      self.identifier = identifier
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    let translationCode: String
    var body: String

    var data: Data? { .init(hex: body) }

    var text: String? {
      guard let data else { return nil }

      switch translationCode {
        case "U":
          return .init(
            data: data,
            encoding: .utf16
          )  // technically it's UCS-2, but this is close neough
        case "A": return .init(data: data, encoding: .ascii)
        default:
          // ISO/IEC 8859 part number (1 to 16); proprietary "P<aaa>" codes are undecodable here
          guard let part = Int(translationCode),
            let encoding = String.Encoding.iso8859(part: part)
          else { return nil }
          return .init(data: data, encoding: encoding)
      }
    }

    mutating func append(payloadOnly other: Self) {
      body.append(contentsOf: other.body)
    }
  }

  enum TUTErrors: Error {
    case badData
  }
}
