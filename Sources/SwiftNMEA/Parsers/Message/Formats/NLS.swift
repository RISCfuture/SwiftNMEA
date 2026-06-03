import Foundation

class NLSParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .navigationLightStatus
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let messageID = try parseMessageID(sentence: sentence)
    let lightCount = try sentence.fields.int(at: 3)!
    guard lightCount >= 1 else {
      throw sentence.fields.fieldError(type: .badValue, index: 3)
    }

    let lights = try (0..<lightCount).map { lightIndex -> NavigationLight in
      let base = 4 + lightIndex * 3
      let identifier = try sentence.fields.int(at: base)!
      guard identifier >= 1 else {
        throw sentence.fields.fieldError(type: .badValue, index: base)
      }
      let status = try sentence.fields.enumeration(
        at: base + 1,
        ofType: NavigationLight.Status.self,
        optional: true
      )
      let hours = try parseRemainingHours(sentence: sentence, index: base + 2)
      return NavigationLight(
        identifier: UInt(identifier),
        status: status,
        remainingWorkingHours: hours
      )
    }

    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      lights: lights
    )

    // A single-sentence message may omit the sequential message identifier
    // (see comment 2). With no identifier to buffer against, emit it directly.
    guard messageID != nil || totalSentences > 1 else {
      guard element.isComplete else {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
      }
      let recipient = Recipient(sentence: sentence, messageID: nil)
      return makePayload(recipient: recipient, element: element)
    }

    let recipient = messageID.map { Recipient(sentence: sentence, messageID: $0) }

    do {
      let finished = try buffer.add(element: element, optionallyFor: recipient)

      return finished.map { recipient, element in
        makePayload(recipient: recipient, element: element)
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

  private func parseMessageID(sentence: ParametricSentence) throws -> UInt? {
    guard let raw = try sentence.fields.int(at: 2, optional: true) else { return nil }
    guard (0...99).contains(raw) else {
      throw sentence.fields.fieldError(type: .badValue, index: 2)
    }
    return UInt(raw)
  }

  private func parseRemainingHours(
    sentence: ParametricSentence,
    index: Int
  ) throws -> NavigationLight.RemainingWorkingHours? {
    guard let raw = try sentence.fields.int(at: index, optional: true) else { return nil }
    guard raw >= 0, let hours = NavigationLight.RemainingWorkingHours(rawValue: UInt(raw)) else {
      throw sentence.fields.fieldError(type: .badValue, index: index)
    }
    return hours
  }

  private func makePayload(recipient: Recipient, element: BufferElement) -> Message.Payload {
    .navigationLightStatus(id: recipient.messageID, lights: element.lights)
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    let messageID: UInt?

    init(sentence: ParametricSentence, messageID: UInt?) {
      self.talker = sentence.talker
      self.format = sentence.format
      self.messageID = messageID
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var lights = [NavigationLight]()

    mutating func append(payloadOnly other: NLSParser.BufferElement) {
      lights.append(contentsOf: other.lights)
    }
  }
}
