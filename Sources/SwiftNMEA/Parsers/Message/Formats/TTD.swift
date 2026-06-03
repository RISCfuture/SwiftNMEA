import Foundation
import NMEACommon

class TTDParser: MessageFormat {
  private var buffer = SixBitBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .encapsulated && sentence.format == .trackedTargets
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.hex(at: 0, width: 2)!
    let sentenceNumber = try sentence.fields.hex(at: 1, width: 2)!
    let sequentialID = try sentence.fields.int(at: 2, optional: true)
    let data = try sentence.fields.string(at: 3)!
    let fillBits = try sentence.fields.int(at: 4)!

    let recipient = Recipient(sentence: sentence, sequentialID: sequentialID)

    do {
      let element = BufferElement(
        lastSentence: Int(sentenceNumber),
        totalSentences: Int(totalSentences),
        encapsulatedData: data,
        fillBits: fillBits
      )
      let finished = try buffer.add(element: element, optionallyFor: recipient)

      do {
        return try zipOptionals(finished?.0, finished?.1).flatMap { recipient, element in
          try makePayload(recipient: recipient, element: element)
        }
      } catch let error as TTDErrors {
        switch error {
          case .badData:
            throw sentence.fields.fieldError(type: .badSixBitEncoding, index: 3)
        }
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

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    // complete messages are flushed upon receipt of the last message
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return try flushed.compactMap { recipient, element in
      do {
        guard let payload = try makePayload(recipient: recipient, element: element) else {
          return nil
        }
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as TTDErrors {
        switch error {
          case .badData:
            return MessageError(type: .badSixBitEncoding, fieldNumber: 3)
        }
      }
    }
  }

  private func makePayload(recipient _: Recipient, element: BufferElement) throws -> Message
    .Payload?
  {
    guard let targets = try element.targets() else { throw TTDErrors.badData }
    return .trackedTargets(targets)
  }

  private struct Recipient: BufferRecipient {
    let talker: Talker
    let format: Format
    var sequentialID: Int?

    init(sentence: ParametricSentence, sequentialID: Int?) {
      talker = sentence.talker
      format = sentence.format
      self.sequentialID = sequentialID
    }
  }

  private struct BufferElement: SixBitElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var encapsulatedData: String
    var fillBits: Int

    func targets() throws -> [Radar.TrackedTarget]? {
      guard let data else { return nil }
      var reader = BitReader(data: data)
      var targets: [Radar.TrackedTarget] = []

      // A sentence may mix protocol-zero (90-bit) and protocol-one (42-bit)
      // structures. Consume them sequentially until fewer than the smallest
      // structure remains (the tail is fill/padding bits).
      while reader.remainingBits >= 42 {
        do {
          targets.append(try .init(reader: &reader))
        } catch Radar.TrackedTarget.DecodingError.unknownProtocolVersion {
          throw TTDErrors.badData
        } catch Radar.TrackedTarget.DecodingError.truncated {
          // Remaining bits are padding, not a complete structure.
          break
        }
      }

      return targets
    }

    mutating func append(otherFields _: Self) {
      // no other fields
    }
  }

  private enum TTDErrors: Error {
    case badData
  }
}
