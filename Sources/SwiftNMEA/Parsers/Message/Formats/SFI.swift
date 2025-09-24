import Foundation
import NMEAUnits

class SFIParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .scanningFrequencies
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let frequencies = try (0..<6).compactMap { index in
      let freqIndex = index * 2 + 2
      let modeIndex = index * 2 + 3
      let freq = try sentence.fields.enumeration(
        at: freqIndex,
        ofType: Comm.Frequency.self,
        optional: true
      )
      let mode = try sentence.fields.enumeration(
        at: modeIndex,
        ofType: Comm.OperationMode.self,
        optional: true
      )

      return freq.map { Comm.FrequencyMode(frequency: $0, mode: mode) }
    }

    let recipient = Recipient(sentence: sentence)
    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      frequencies: frequencies
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        makePayload(element: finishedElement)
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
    if !includeIncomplete { return [] }  // complete messages are flushed upon receipt of the last message

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    return flushed.compactMap { recipient, element in
      let payload = makePayload(element: element)
      return Message(talker: recipient.talker, format: recipient.format, payload: payload)
    }
  }

  private func makePayload(element: BufferElement) -> Message.Payload {
    return .scanningFrequencies(element.frequencies)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    let format = Format.scanningFrequencies

    init(sentence: ParametricSentence) {
      talker = sentence.talker
    }
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    var frequencies = [Comm.FrequencyMode]()

    mutating func append(payloadOnly other: Self) {
      frequencies.append(contentsOf: other.frequencies)
    }
  }
}
