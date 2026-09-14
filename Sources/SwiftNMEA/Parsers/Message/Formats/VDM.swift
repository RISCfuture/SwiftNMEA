import Foundation
import NMEACommon

class VDMParser: MessageFormat {
  private var buffer = SixBitBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .encapsulated && sentence.format == .VDLMessage
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let sequentialID = try sentence.fields.int(at: 2, optional: true)
    let channel = try sentence.fields.enumeration(at: 3, ofType: AIS.Channel.self, optional: true)
    let data = try sentence.fields.string(at: 4)!
    let fillBits = try sentence.fields.int(at: 5)!

    let recipient = Recipient(sentence: sentence, sequentialID: sequentialID)
    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      channel: channel,
      encapsulatedData: data,
      fillBits: fillBits
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
        case .badData: throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 4)
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
          return MessageError(type: .badSixBitEncoding, fieldNumber: 4)
      }
    }
  }

  private func makePayload(recipient _: Recipient, element: BufferElement) throws(VDMErrors)
    -> Message.Payload?
  {
    guard let data = element.data else { throw VDMErrors.badData }
    return .VDLMessage(data, channel: element.channel)
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    let sequentialID: Int?

    init(sentence: ParametricSentence, sequentialID: Int?) {
      self.talker = sentence.talker
      self.format = sentence.format
      self.sequentialID = sequentialID
    }
  }

  private struct BufferElement: SixBitElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    let channel: AIS.Channel?
    var encapsulatedData: String
    var fillBits: Int

    func append(otherFields _: Self) {
      // nothing by default
    }
  }

  private enum VDMErrors: Error {
    case badData
  }
}
