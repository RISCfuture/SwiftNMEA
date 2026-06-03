import Foundation

class TRLParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISTransmitterNonFunctioningLog
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalEntries = try sentence.fields.int(at: 0)!

    // When a query is received and no log entries exist, the total is "0" and
    // all other fields (including the sequential message identifier) are null.
    // This is a complete, self-contained sentence.
    if totalEntries == 0 {
      let messageID = try sentence.fields.int(at: 2, optional: true)
      return .AISTransmitterNonFunctioningLog(id: messageID, entries: [])
    }

    let messageID = try sentence.fields.int(at: 2)!
    let entryNumber = try sentence.fields.int(at: 1)!
    let switchOff = try sentence.fields.datetime(ymdIndex: 3, hmsDecimalIndex: 4)!
    let switchOn = try sentence.fields.datetime(ymdIndex: 5, hmsDecimalIndex: 6)!
    let reason = try sentence.fields.enumeration(
      at: 7,
      ofType: AIS.TransmitterNonFunctioningReason.self
    )!

    let entry = AIS.TransmitterNonFunctioningLogEntry(
      number: entryNumber,
      switchOff: switchOff,
      switchOn: switchOn,
      reason: reason
    )

    let recipient = Recipient(talker: sentence.talker, messageID: messageID)
    let element = BufferElement(
      lastSentence: entryNumber,
      totalSentences: totalEntries,
      entries: [entry]
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        makePayload(recipient: recipient, element: finishedElement)
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
    // complete messages are flushed upon receipt of the last log entry
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.map { recipient, element in
      let payload = makePayload(recipient: recipient, element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload {
    let sorted = element.entries.sorted { $0.number < $1.number }
    return .AISTransmitterNonFunctioningLog(id: recipient.messageID, entries: sorted)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    var format: Format = .AISTransmitterNonFunctioningLog
    var messageID: Int
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // appended
    var entries: [AIS.TransmitterNonFunctioningLogEntry]

    mutating func append(payloadOnly other: TRLParser.BufferElement) {
      entries.append(contentsOf: other.entries)
    }
  }
}
