import Foundation
import NMEACommon
import NMEAUnits

class TUTParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .multiLanguageText
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let source = try sentence.fields.enumeration(at: 0, ofType: Talker.self)!
    let totalSentences = try sentence.fields.int(at: 1)!
    let sentenceNumber = try sentence.fields.int(at: 2)!
    let identifier = try sentence.fields.int(at: 3, optional: true)
    let translationCode = try sentence.fields.string(at: 4)!
    let body = try sentence.fields.string(at: 5)!

    do {
      let recipient = identifier.map { identifier in
        Recipient(
          sentence: sentence,
          source: source,
          identifier: identifier
        )
      }
      let element = BufferElement(
        lastSentence: sentenceNumber,
        totalSentences: totalSentences,
        translationCode: translationCode,
        body: body
      )
      let finished = try buffer.add(
        element: element,
        optionallyFor: recipient
      )

      return try zipOptionals(finished?.0, finished?.1)
        .map { recipient, element in
          try makePayload(recipient: recipient, element: element)
        }
    } catch let error as TUTErrors {
      switch error {
        case .badData: throw sentence.fields.fieldError(type: .badValue, index: 5)
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
    if !includeIncomplete {
      return []
    }  // complete messages are flushed upon receipt of the last message

    let flushed = buffer.flush(
      talker: talker,
      format: format,
      includeIncomplete: includeIncomplete
    )
    return try flushed.compactMap { recipient, element in
      do {
        let payload = try makePayload(recipient: recipient, element: element)
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as TUTErrors {
        switch error {
          case .badData:
            return MessageError(type: .badValue, fieldNumber: 5)
        }
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
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
        case "1"..."16":
          guard let part = Int(translationCode),
            let encoding = String.Encoding.iso8859(part: part)
          else { return nil }
          return .init(data: data, encoding: encoding)
        default: return nil
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
