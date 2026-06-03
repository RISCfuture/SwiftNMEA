import Foundation

class GENParser: MessageFormat {
  private let binaryParser = PackedBinaryCoder()
  private var buffer = DataBuffer()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .genericBinary
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let index = try sentence.fields.hex(at: 0, width: 4)!
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)
    let chunks = sentence.fields[2...]

    do {
      // map each packed field’s relative offset → decoded bytes, then re-key by
      // its absolute 16-bit entity index (null fields produce no entry)
      let relativeEntities = try binaryParser.decodeEntities(chunks)
      let entities = relativeEntities.reduce(into: [UInt16: Data]()) { entities, entity in
        entities[UInt16(index) + UInt16(entity.key)] = entity.value
      }

      let recipient = DataBuffer.Recipient(sentence: sentence, timestamp: time)
      try buffer.add(element: .init(entities: entities), for: recipient)

      return nil  // must be retrieved with flush()
    } catch let error as PackedBinaryCoder.Errors {
      switch error {
        case .invalidChunk(let index):
          throw sentence.fields.fieldError(type: .badNumericValue, index: index + 2)
      }
    }
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    if !includeIncomplete { return [] }  // open-ended buffer is always incomplete

    return buffer.flush(talker: talker, format: format, includeIncomplete: true).map {
      recipient,
      element in
      let payload = Message.Payload.genericBinary(
        time: recipient.timestamp,
        entities: element.entities
      )
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private struct DataBuffer: Buffer {
    var buffer = [Recipient: Element]()

    struct Recipient: BufferRecipient {
      let talker: Talker
      let format: Format
      let timestamp: Date?

      init(sentence: ParametricSentence, timestamp: Date?) {
        self.talker = sentence.talker
        self.format = sentence.format
        self.timestamp = timestamp
      }
    }

    struct Element: BufferElement {
      var entities: [UInt16: Data]
      var isComplete: Bool { false }

      init(entities: [UInt16: Data]) {
        self.entities = entities
      }

      mutating func append(_ other: Self) throws {
        entities.merge(other.entities) { _, new in new }
      }
    }
  }
}
