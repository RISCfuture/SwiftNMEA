import Foundation

class ALCParser: MessageFormat {
  private static let entryFieldCount = 4
  private static let entryStartIndex = 4

  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .cyclicAlertList
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let sequentialID = try sentence.fields.int(at: 2)!
    let numberOfEntries = try sentence.fields.int(at: 3)!
    guard numberOfEntries >= 0 else {
      throw sentence.fields.fieldError(type: .badValue, index: 3)
    }

    // Alert entries beyond the declared number are ignored (comment 3).
    let entries = try (0..<numberOfEntries).map { entry in
      try parseEntry(sentence: sentence, entry: entry)
    }

    do {
      let recipient = Recipient(sentence: sentence, sequentialID: sequentialID)
      let element = BufferElement(
        lastSentence: sentenceNumber,
        totalSentences: totalSentences,
        entries: entries
      )
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        makePayload(recipient: recipient, element: finishedElement)
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

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) -> [any Element] {
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.map { recipient, element in
      let payload = makePayload(recipient: recipient, element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private func parseEntry(sentence: ParametricSentence, entry: Int) throws -> Alert.ListEntry {
    let base = Self.entryStartIndex + entry * Self.entryFieldCount
    let mnemonicIndex = base
    let identifierIndex = base + 1
    let instanceIndex = base + 2
    let revisionIndex = base + 3

    let mnemonic = try sentence.fields.string(at: mnemonicIndex, optional: true)

    let rawIdentifier = try sentence.fields.int(at: identifierIndex)!
    guard rawIdentifier >= 0 else {
      throw sentence.fields.fieldError(type: .badValue, index: identifierIndex)
    }

    let rawInstance = try sentence.fields.int(at: instanceIndex, optional: true)
    if let rawInstance, rawInstance < 0 {
      throw sentence.fields.fieldError(type: .badValue, index: instanceIndex)
    }

    let rawRevision = try sentence.fields.int(at: revisionIndex)!
    guard rawRevision >= 1, rawRevision <= 99 else {
      throw sentence.fields.fieldError(type: .badValue, index: revisionIndex)
    }

    let identifier = Alert.Identifier(
      manufacturerMnemonic: mnemonic,
      identifier: UInt(rawIdentifier),
      instance: rawInstance.map(UInt.init)
    )
    return .init(identifier: identifier, revisionCounter: UInt(rawRevision))
  }

  private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload {
    .cyclicAlertList(element.entries, sequentialID: recipient.sequentialID)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    let format = Format.cyclicAlertList
    let sequentialID: Int

    init(sentence: ParametricSentence, sequentialID: Int) {
      talker = sentence.talker
      self.sequentialID = sequentialID
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var entries = [Alert.ListEntry]()

    mutating func append(payloadOnly other: Self) {
      entries.append(contentsOf: other.entries)
    }
  }
}
