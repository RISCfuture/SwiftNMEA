import Foundation
import NMEACommon

class BBMParser: MessageFormat {
  private var buffer = SixBitBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .encapsulated && sentence.format == .AISBroadcastBinaryMessage
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let sequentialID = try sentence.fields.int(at: 2)!
    let channel = try sentence.fields.enumeration(
      at: 3,
      ofType: AIS.BroadcastChannel.self,
      optional: true
    )
    let messageID = try sentence.fields.enumeration(
      at: 4,
      ofType: AIS.MessageID.self,
      optional: true
    )
    let data = try sentence.fields.string(at: 5)!
    let fillBits = try sentence.fields.int(at: 6)!

    let recipient = zipOptionals(channel, messageID).map { channel, messageID in
      Recipient(
        sentence: sentence,
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
          if channel == nil {
            throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
          }
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 4)
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
          throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 5)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool = false) throws(NMEAError)
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
          return MessageError(type: .badSixBitEncoding, fieldNumber: 5)
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws(BBMErrors)
    -> Message.Payload?
  {
    guard let data = element.data else { throw BBMErrors.badData }

    return .AISBroadcastBinaryMessage(
      sequentialIdentifier: recipient.sequentialID,
      channel: recipient.channel,
      messageID: recipient.messageID,
      data: data
    )
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    let channel: AIS.BroadcastChannel
    let messageID: AIS.MessageID
    var sequentialID: Int

    init(
      sentence: ParametricSentence,
      channel: AIS.BroadcastChannel,
      messageID: AIS.MessageID,
      sequentialID: Int
    ) {
      self.talker = sentence.talker
      self.format = sentence.format
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

    mutating func append(otherFields _: Self) {
      // no other fields
    }
  }

  private enum BBMErrors: Error {
    case badData
  }
}
