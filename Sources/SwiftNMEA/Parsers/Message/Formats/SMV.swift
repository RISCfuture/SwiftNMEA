import Foundation
import NMEACommon

class SMVParser: MessageFormat {
  private static let coder = EscapedStringCoder()

  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }()

  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .safetyNETVesselDistress
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1, optional: true)
    let identifier = try sentence.fields.int(at: 2, optional: true)
    let uniqueMessageNumber = try sentence.fields.int(at: 3)!
    let mmsi = try sentence.fields.int(at: 4, optional: true)
    let name = try sentence.fields.string(at: 5, optional: true)
    let position = try sentence.fields.position(
      latitudeIndex: (6, 7),
      longitudeIndex: (8, 9),
      optional: true
    )
    let positionTime = try positionTime(from: sentence)
    let status = try sentence.fields.enumeration(
      at: 15,
      ofType: SafetyNET.VesselDistressStatus.self
    )!

    guard uniqueMessageNumber >= 0, uniqueMessageNumber <= 999_999 else {
      throw sentence.fields.fieldError(type: .badValue, index: 3)
    }
    if let identifier, identifier < 0 || identifier > 9 {
      throw sentence.fields.fieldError(type: .badValue, index: 2)
    }
    if let mmsi, mmsi < 0 {
      throw sentence.fields.fieldError(type: .badValue, index: 4)
    }

    // The sentence number may be null only when the total number of sentences
    // is "1"; for a single-sentence message we treat the implicit sentence
    // number as 1.
    let lastSentence = sentenceNumber ?? 1

    let recipient = Recipient(
      talker: sentence.talker,
      uniqueMessageNumber: UInt(uniqueMessageNumber),
      identifier: identifier.map(UInt.init)
    )
    let element = BufferElement(
      lastSentence: lastSentence,
      totalSentences: totalSentences,
      mmsi: mmsi,
      name: name,
      position: position,
      positionTime: positionTime,
      status: status
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        try makePayload(recipient: recipient, element: finishedElement)
      }
    } catch let error as SMVErrors {
      throw error.lineError(in: sentence)
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
    // complete messages are flushed upon receipt of the last sentence
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(
      talker: talker,
      format: format,
      includeIncomplete: includeIncomplete
    )

    return try flushed.map { recipient, element in
      do {
        let payload = try makePayload(recipient: recipient, element: element)
        return Message(talker: recipient.talker, format: recipient.format, payload: payload)
      } catch let error as SMVErrors {
        return error.messageError
      }
    }
  }

  private func positionTime(from sentence: ParametricSentence) throws -> Date? {
    guard let year = try sentence.fields.int(at: 10, optional: true),
      let month = try sentence.fields.int(at: 11, optional: true),
      let day = try sentence.fields.int(at: 12, optional: true),
      let hour = try sentence.fields.int(at: 13, optional: true),
      let minute = try sentence.fields.int(at: 14, optional: true)
    else { return nil }

    let components = DateComponents(
      timeZone: .gmt,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    )
    guard let date = calendar.date(from: components), components.isValidDate(in: calendar) else {
      throw sentence.fields.lineError(type: .badDate)
    }
    return date
  }

  private func makePayload(recipient: Recipient, element: BufferElement) throws -> Message.Payload {
    let name: String?
    if let rawName = element.name {
      guard let decoded = Self.coder.decode(string: rawName) else {
        throw SMVErrors.badName
      }
      name = decoded
    } else {
      name = nil
    }

    return .safetyNETVesselDistress(
      uniqueMessageNumber: recipient.uniqueMessageNumber,
      identifier: recipient.identifier,
      mmsi: element.mmsi,
      vesselName: name,
      position: element.position,
      positionTime: element.positionTime,
      status: element.status
    )
  }

  private enum SMVErrors: Error {
    case badName

    var fieldNumber: Int {
      switch self {
        case .badName: 5
      }
    }

    var errorType: ErrorType {
      switch self {
        case .badName: .badEncoding
      }
    }

    var messageError: MessageError {
      .init(type: errorType, fieldNumber: fieldNumber)
    }

    func lineError(in sentence: ParametricSentence) -> NMEAError {
      sentence.fields.fieldError(type: errorType, index: fieldNumber)
    }
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    let format = Format.safetyNETVesselDistress
    let uniqueMessageNumber: UInt
    let identifier: UInt?
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // written once across the sentences forming a message
    var mmsi: Int?
    var name: String?
    var position: Position?
    var positionTime: Date?
    var status: SafetyNET.VesselDistressStatus

    mutating func append(payloadOnly other: Self) {
      mmsi ??= other.mmsi
      name ??= other.name
      position ??= other.position
      positionTime ??= other.positionTime
      // `status` is present and identical in every sentence of a message
      // (comment 12), so the value captured from the first sentence is kept.
    }
  }
}
