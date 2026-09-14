import Foundation

class GENParser: MessageFormat {
  private let binaryParser = PackedBinaryCoder()
  private var buffer = DataBuffer()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .genericBinary
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let index = try sentence.fields.hex(at: 0, width: 4)!
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)
    let chunks = sentence.fields[2...]

    // map each packed field’s relative offset → decoded bytes, then re-key by
    // its absolute 16-bit entity index (null fields produce no entry)
    let relativeEntities: [Int: Data]
    do {
      relativeEntities = try binaryParser.decodeEntities(chunks)
    } catch {
      switch error {
        case .invalidChunk(let index):
          throw sentence.fields.fieldError(type: .badNumericValue, index: index + 2)
      }
    }

    var entities = [UInt16: Data]()
    for entity in relativeEntities {
      // entity.key is a non-negative relative offset; guard the absolute
      // 16-bit entity index instead of trapping on UInt16 overflow.
      let absoluteKey = index + UInt(entity.key)
      guard absoluteKey <= UInt(UInt16.max) else {
        throw sentence.fields.fieldError(type: .badNumericValue, index: 0)
      }
      entities[UInt16(absoluteKey)] = entity.value
    }

    let recipient = DataBuffer.Recipient(sentence: sentence, timestamp: time)
    buffer.add(element: .init(entities: entities), for: recipient)

    return nil  // must be retrieved with flush()
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
  {
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

      mutating func append(_ other: Self) {
        entities.merge(other.entities) { _, new in new }
      }
    }
  }
}
