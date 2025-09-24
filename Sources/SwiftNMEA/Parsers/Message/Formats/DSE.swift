import Algorithms
import Foundation
import NMEACommon
import SwiftDSE

class DSEParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .DSE
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let type = try sentence.fields.enumeration(at: 2, ofType: DSE.MessageType.self, optional: true)
    let MMSI = try sentence.fields.int(at: 3, optional: true).map { $0 / 10 }
    let fields = sentence.fields[4...]

    let recipient = zipOptionals(MMSI, type).map { MMSI, type in
      Recipient(sentence: sentence, MMSI: MMSI, type: type)
    }

    let messages = try fields.chunks(ofCount: 2).enumerated().map { index, pair in
      guard pair.count == 2 else {
        throw sentence.fields.lineError(type: .missingRequiredValue)
      }
      guard let command = pair.first! else {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: index * 2 + 4)
      }
      guard let message = SwiftDSE.parse(format: command, data: pair.last!, isQuery: type == .query)
      else {
        throw sentence.fields.lineError(type: .badValue)
      }
      return message
    }

    do {
      let element = BufferElement(
        lastSentence: sentenceNumber,
        totalSentences: totalSentences,
        messages: messages
      )
      let finished = try buffer.add(element: element, optionallyFor: recipient)

      return zipOptionals(finished?.0, finished?.1).flatMap { recipient, element in
        makePayload(recipient: recipient, element: element)
      }
    } catch let error as BufferErrors {
      switch error {
        case .missingRecipient:
          if MMSI == nil {
            throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
          }
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    if !includeIncomplete { return [] }  // complete messages are flushed upon receipt of the last message

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.compactMap { recipient, element in
      guard let payload = makePayload(recipient: recipient, element: element) else { return nil }
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload? {
    return .DSE(type: recipient.type, MMSI: recipient.MMSI, data: element.messages)
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    let MMSI: Int
    let type: DSE.MessageType

    init(sentence: ParametricSentence, MMSI: Int, type: DSE.MessageType) {
      self.talker = sentence.talker
      self.format = sentence.format
      self.MMSI = MMSI
      self.type = type
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var messages = [SwiftDSE.Message]()

    mutating func append(payloadOnly other: DSEParser.BufferElement) {
      messages.append(contentsOf: other.messages)
    }
  }
}
