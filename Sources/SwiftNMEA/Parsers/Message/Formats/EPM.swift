import Foundation

class EPMParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()
  private let decoder = EscapedStringCoder()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .equipmentPropertyLong
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let lastSentence = try sentence.fields.int(at: 1)!
    let messageID = try sentence.fields.int(at: 2)!
    let status = try sentence.fields.enumeration(at: 3, ofType: SentenceType.self)!
    let type = try sentence.fields.enumeration(at: 4, ofType: Talker.self)!
    let uniqueID = try sentence.fields.string(at: 5, optional: true)
    guard let rawProperty = try sentence.fields.int(at: 6), rawProperty >= 0 else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 6)
    }
    let value = try sentence.fields.string(at: 7)!

    let reference = EquipmentProperty.Reference(type: type, uniqueID: uniqueID)
    let property = EquipmentProperty.Identifier(rawValue: UInt(rawProperty))

    let recipient = Recipient(talker: sentence.talker, uniqueID: uniqueID, messageID: messageID)
    let element = BufferElement(
      lastSentence: lastSentence,
      totalSentences: totalSentences,
      status: status,
      reference: reference,
      property: property,
      value: value
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        try makePayload(element: finishedElement)
      }
    } catch let error as EPMErrors {
      switch error {
        case .badValue(let index):
          throw sentence.fields.fieldError(type: .badValue, index: index)
      }
    } catch let error as BufferErrors {
      switch error {
        case .missingRecipient:
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return try flushed.map { recipient, element in
      do {
        let payload = try makePayload(element: element)
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as EPMErrors {
        switch error {
          case .badValue(let index):
            return MessageError(type: .badValue, fieldNumber: index)
        }
      }
    }
  }

  private func makePayload(element: BufferElement) throws -> Message.Payload {
    guard let value = decoder.decode(string: element.value) else {
      throw EPMErrors.badValue(index: 7)
    }

    return .equipmentPropertyLong(
      type: element.status,
      reference: element.reference,
      property: element.property,
      value: value
    )
  }

  private enum EPMErrors: Error {
    case badValue(index: Int)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    var format: Format = .equipmentPropertyLong
    var uniqueID: String?
    var messageID: Int
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // written once
    var status: SentenceType
    var reference: EquipmentProperty.Reference
    var property: EquipmentProperty.Identifier

    // appended
    var value: String

    mutating func append(payloadOnly other: EPMParser.BufferElement) {
      value.append(other.value)
    }
  }
}
