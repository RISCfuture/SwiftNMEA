import Foundation
import NMEACommon

class ALFParser: MessageFormat {
  private static let coder = EscapedStringCoder()

  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alert
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let sequentialID = try sentence.fields.int(at: 2, optional: true)
    let time = try sentence.fields.hmsDecimal(at: 3, searchDirection: .backward, optional: true)
    let category = try sentence.fields.enumeration(
      at: 4,
      ofType: Alert.Category.self,
      optional: true
    )
    let priority = try sentence.fields.enumeration(
      at: 5,
      ofType: Alert.Priority.self,
      optional: true
    )
    let state = try sentence.fields.enumeration(at: 6, ofType: Alert.State.self, optional: true)
    let mnemonic = try sentence.fields.string(at: 7, optional: true)

    let rawIdentifier = try sentence.fields.int(at: 8)!
    guard rawIdentifier >= 0 else {
      throw sentence.fields.fieldError(type: .badValue, index: 8)
    }
    let rawInstance = try sentence.fields.int(at: 9, optional: true)
    let instance: UInt?
    if let rawInstance {
      guard rawInstance >= 0 else {
        throw sentence.fields.fieldError(type: .badValue, index: 9)
      }
      instance = UInt(rawInstance)
    } else {
      instance = nil
    }
    let identifier = Alert.Identifier(
      manufacturerMnemonic: mnemonic,
      identifier: UInt(rawIdentifier),
      instance: instance
    )

    let rawRevision = try sentence.fields.int(at: 10, optional: true)
    let revisionCounter: UInt?
    if let rawRevision {
      guard rawRevision >= 0 else {
        throw sentence.fields.fieldError(type: .badValue, index: 10)
      }
      revisionCounter = UInt(rawRevision)
    } else {
      revisionCounter = nil
    }

    let rawEscalation = try sentence.fields.int(at: 11, optional: true)
    let escalationCounter: UInt?
    if let rawEscalation {
      guard rawEscalation >= 0 else {
        throw sentence.fields.fieldError(type: .badValue, index: 11)
      }
      escalationCounter = UInt(rawEscalation)
    } else {
      escalationCounter = nil
    }

    let text = try sentence.fields.string(at: 12)!

    let recipient = sequentialID.map { sequentialID in
      Recipient(sentence: sentence, sequentialID: sequentialID)
    }
    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      identifier: identifier,
      time: time,
      category: category,
      priority: priority,
      state: state,
      revisionCounter: revisionCounter,
      escalationCounter: escalationCounter,
      texts: [sentenceNumber: text]
    )

    do {
      let finished = try buffer.add(element: element, optionallyFor: recipient)

      return try zipOptionals(finished?.0, finished?.1).map { recipient, element in
        try makePayload(recipient: recipient, element: element)
      }
    } catch let error as ALFErrors {
      switch error {
        case .badText(let index): throw sentence.fields.fieldError(type: .badEncoding, index: index)
      }
    } catch let error as BufferErrors {
      switch error {
        case .missingRecipient:
          // Per comment 2, the sequential message identifier may be a null
          // field only for a single-sentence message; such a message is
          // self-contained and needs no buffering. For a multi-sentence
          // message the identifier is required.
          guard totalSentences == 1 else {
            throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
          }
          return try makePayload(
            recipient: Recipient(sentence: sentence, sequentialID: nil),
            element: element
          )
        case .wrongSentenceNumber:
          throw sentence.fields.fieldError(type: .wrongSentenceNumber, index: 1)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return try flushed.compactMap { recipient, element in
      do {
        let payload = try makePayload(recipient: recipient, element: element)
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as ALFErrors {
        switch error {
          case .badText(let index):
            return MessageError(type: .badEncoding, fieldNumber: index)
        }
      }
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
    // the first sentence carries the alert title; an optional second sentence
    // carries the additional alert description (see comment 12)
    guard let rawTitle = element.texts[1] else { throw ALFErrors.badText(index: 12) }
    guard let title = Self.coder.decode(string: rawTitle) else {
      throw ALFErrors.badText(index: 12)
    }

    var description: String?
    if let rawDescription = element.texts[2] {
      guard let decoded = Self.coder.decode(string: rawDescription) else {
        throw ALFErrors.badText(index: 12)
      }
      description = decoded
    }

    return .alert(
      element.identifier,
      sequentialMessageID: recipient.sequentialID,
      time: element.time,
      category: element.category,
      priority: element.priority,
      state: element.state,
      revisionCounter: element.revisionCounter,
      escalationCounter: element.escalationCounter,
      title: title,
      description: description
    )
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format = Format.alert
    let sequentialID: Int?

    init(sentence: ParametricSentence, sequentialID: Int?) {
      talker = sentence.talker
      self.sequentialID = sequentialID
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // written once, taken from the first sentence
    var identifier: Alert.Identifier
    var time: Date?
    var category: Alert.Category?
    var priority: Alert.Priority?
    var state: Alert.State?
    var revisionCounter: UInt?
    var escalationCounter: UInt?

    // text keyed by sentence number: 1 = alert title, 2 = additional description
    var texts: [Int: String]

    mutating func append(payloadOnly other: Self) {
      // The metadata is carried by the first ALF sentence; the second sentence
      // sends null fields for time/category/priority/state (comment 12). Fill
      // in any field this element is missing so the merge is order-independent.
      time ??= other.time
      category ??= other.category
      priority ??= other.priority
      state ??= other.state
      revisionCounter ??= other.revisionCounter
      escalationCounter ??= other.escalationCounter
      texts.merge(other.texts) { current, _ in current }
    }
  }

  private enum ALFErrors: Error {
    case badText(index: Int)
  }
}
