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
    let chunksOpt = sentence.fields[2...]
    let chunks = chunksOpt.compactMap(\.self)

    guard chunks.count == chunksOpt.count else {
      throw sentence.fields.lineError(type: .missingRequiredValue)
    }

    do {
      let data = try binaryParser.decode(chunks)
      let recipient = DataBuffer.Recipient(sentence: sentence, timestamp: time)
      try buffer.add(element: .init(data: data, index: Int(index)), for: recipient)

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
      let payload = Message.Payload.genericBinary(time: recipient.timestamp, data: element.data)
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
      var data: Data
      var originalData: Data
      var index: Int
      var isComplete: Bool { false }

      init(data: Data, index: Int) {
        originalData = data
        self.index = index * 2  // 2 bytes per four-character hex group
        var paddedData = Data(count: self.index + data.count)
        paddedData.replace(with: data, from: self.index)
        self.data = paddedData
      }

      mutating func append(_ other: Self) throws {
        data.replace(with: other.originalData, from: other.index)
      }
    }
  }
}
