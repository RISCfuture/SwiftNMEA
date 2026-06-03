import Foundation

class AGLParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alertGroupList
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let lastSentence = try sentence.fields.int(at: 1)!
    let messageID = try sentence.fields.int(at: 2)!

    // each alert entry is four fields: SFI, manufacturer mnemonic, identifier,
    // instance, starting after the three header fields
    var entries = [AlertGroupEntry]()
    for index in stride(from: 3, to: sentence.fields.count, by: 4) {
      let systemFunctionID = try sentence.fields.string(at: index, optional: true)
      let mnemonic = try sentence.fields.string(at: index + 1, optional: true)

      let rawIdentifier = try sentence.fields.int(at: index + 2)!
      guard rawIdentifier >= 0 else {
        throw sentence.fields.fieldError(type: .badValue, index: index + 2)
      }
      let identifier = UInt(rawIdentifier)

      var instance: UInt?
      if let rawInstance = try sentence.fields.int(at: index + 3, optional: true) {
        guard rawInstance >= 0 else {
          throw sentence.fields.fieldError(type: .badValue, index: index + 3)
        }
        instance = UInt(rawInstance)
      }

      let alert = Alert.Identifier(
        manufacturerMnemonic: mnemonic,
        identifier: identifier,
        instance: instance
      )
      entries.append(AlertGroupEntry(systemFunctionID: systemFunctionID, alert: alert))
    }

    let recipient = Recipient(talker: sentence.talker, messageID: messageID)
    let element = BufferElement(
      lastSentence: lastSentence,
      totalSentences: totalSentences,
      entries: entries
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
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.map { recipient, element in
      let payload = makePayload(recipient: recipient, element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload {
    .alertGroupList(id: recipient.messageID, entries: element.entries)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    var format: Format = .alertGroupList
    var messageID: Int
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // appended
    var entries: [AlertGroupEntry]

    mutating func append(payloadOnly other: AGLParser.BufferElement) {
      entries.append(contentsOf: other.entries)
    }
  }
}
