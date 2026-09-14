import Foundation
import NMEACommon

class ABMParser: MessageFormat {
  private var buffer = SixBitBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .encapsulated && sentence.format == .AISBinaryMessage
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let sequentialID = try sentence.fields.int(at: 2)!
    let MMSI = try sentence.fields.int(at: 3, optional: true)
    let channel = try sentence.fields.enumeration(
      at: 4,
      ofType: AIS.BroadcastChannel.self,
      optional: true
    )
    let messageID = try sentence.fields.enumeration(
      at: 5,
      ofType: AIS.MessageID.self,
      optional: true
    )
    let data = try sentence.fields.string(at: 6)!
    let fillBits = try sentence.fields.int(at: 7)!

    let recipient = zipOptionals(MMSI, channel, messageID).map { MMSI, channel, messageID in
      Recipient(
        sentence: sentence,
        MMSI: MMSI,
        channel: channel,
        messageID: messageID,
        sequentialID: sequentialID
      )
    }

    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      encapsulatedData: data,
      fillBits: fillBits
    )

    let finished: (Recipient, BufferElement)?
    do {
      finished = try buffer.add(element: element, optionallyFor: recipient)
    } catch {
      switch error {
        case .missingRecipient:
          if MMSI == nil {
            throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
          }
          if channel == nil {
            throw sentence.fields.fieldError(type: .missingRequiredValue, index: 4)
          }
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 5)
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
    guard let finished else { return nil }

    do {
      return try makePayload(recipient: finished.0, element: finished.1)
    } catch {
      switch error {
        case .badData:
          throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 6)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
  {
    // complete messages are flushed upon receipt of the last message
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.compactMap { recipient, element in
      message(for: recipient, element: element)
    }
  }

  private func message(for recipient: Recipient, element: BufferElement) -> (any Element)? {
    do {
      guard let payload = try makePayload(recipient: recipient, element: element) else {
        return nil
      }
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    } catch {
      switch error {
        case .badData:
          return MessageError(type: .badSixBitEncoding, fieldNumber: 6)
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws(ABMErrors)
    -> Message.Payload?
  {
    guard let data = element.data else { throw ABMErrors.badData }

    return .AISBinaryMessage(
      sequentialIdentifier: recipient.sequentialID,
      MMSI: recipient.MMSI,
      channel: recipient.channel,
      messageID: recipient.messageID,
      data: data
    )
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    let MMSI: Int
    let channel: AIS.BroadcastChannel
    let messageID: AIS.MessageID
    let sequentialID: Int

    init(
      sentence: ParametricSentence,
      MMSI: Int,
      channel: AIS.BroadcastChannel,
      messageID: AIS.MessageID,
      sequentialID: Int
    ) {
      self.talker = sentence.talker
      self.format = sentence.format
      self.MMSI = MMSI
      self.channel = channel
      self.messageID = messageID
      self.sequentialID = sequentialID
    }
  }

  private struct BufferElement: SixBitElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var encapsulatedData: String
    var fillBits: Int

    func append(otherFields _: ABMParser.BufferElement) {
      // no other fields
    }
  }

  private enum ABMErrors: Error {
    case badData
  }
}
