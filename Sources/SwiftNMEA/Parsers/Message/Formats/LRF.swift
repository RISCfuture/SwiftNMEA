import Foundation
import NMEACommon

class LRFParser: MessageFormat {
  private var buffer = LRFBuffer()

  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric
      && (sentence.format == .AISLongRangeFunction || sentence.format == .AISLongRangeReply1
        || sentence.format == .AISLongRangeReply2 || sentence.format == .AISLongRangeReply3)
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    guard let element = try LRFElement(sentence: sentence) else { return nil }
    let recipient = try LRFRecipient(sentence: sentence)

    let finished: LRFElement?
    do {
      finished = try buffer.add(element: element, for: recipient)
    } catch {
      switch error {
        case .formatAlreadySeen, .unexpectedFormat:
          throw sentence.fields.lineError(type: .unexpectedFormat)
      }
    }
    guard let finished else { return nil }

    return try makePayload(recipient: recipient, element: finished)
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
  {
    // complete messages are flushed upon receipt of the last message
    if !includeIncomplete { return [] }

    let flushed = buffer.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    var messages = [any Element]()
    for (recipient, element) in flushed {
      let payload = try makePayload(recipient: recipient, element: element)
      messages.append(Message(talker: recipient.talker, format: recipient.format, payload: payload))
    }
    return messages
  }

  private func makePayload(recipient _: LRFRecipient, element: LRFElement) throws(NMEAError)
    -> Message.Payload
  {
    try .AISLongRangeReply(
      requestorMMSI: element.MMSI,
      requestorName: element.requestorName,
      replyStatuses: element.replyStatuses,
      time: element.time,
      shipName: element.shipName,
      shipCallsign: element.shipCallsign,
      shipIMO: element.shipIMO,
      position: element.position,
      course: element.course,
      speed: element.speed,
      destination: element.destination,
      ETA: element.ETA,
      shipType: element.shipType,
      shipType2: element.shipType2,
      length: element.length,
      breadth: element.breadth,
      draught: element.draught,
      soulsOnboard: element.soulsOnboard
    )
  }

  private struct LRFRecipient: BufferRecipient {
    var talker: Talker
    // placeholder as recipients are not distinguished by format
    let format = Format.AISLongRangeFunction
    var MMSI: Int
    var sequence: Int

    init(sentence: ParametricSentence) throws(NMEAError) {
      talker = sentence.talker
      MMSI = try sentence.fields.int(at: 1)!
      sequence = try sentence.fields.int(at: 0)!
    }
  }

  private struct LRFElement: BufferElement {
    private static let decoder = EscapedStringCoder()

    static let functionFormats: [AISLongRange.Function: Format] = [
      .shipID: .AISLongRangeReply1,
      .position: .AISLongRangeReply2,
      .course: .AISLongRangeReply2,
      .speed: .AISLongRangeReply2,
      .destination: .AISLongRangeReply3,
      .draught: .AISLongRangeReply3,
      .cargo: .AISLongRangeReply3,
      .shipDimensions: .AISLongRangeReply3,
      .soulsOnboard: .AISLongRangeReply3
    ]

    var sentences = [Format: ParametricSentence]()
    var formats: Set<Format>

    var isComplete: Bool { !formats.isEmpty && Set(sentences.keys) == formats }

    var MMSI: Int {
      get throws(NMEAError) {
        guard let sentence = sentences[.AISLongRangeFunction] else {
          throw NMEAError(type: .missingFormat)
        }
        return try sentence.fields.int(at: 1)!
      }
    }

    var requestorName: String? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeFunction]?.fields.string(at: 2, optional: true)
      }
    }

    var replyStatuses: [AISLongRange.Function: AISLongRange.FunctionStatus] {
      get throws(NMEAError) {
        guard let sentence = sentences[.AISLongRangeFunction] else {
          fatalError("Missing LRF sentence")
        }
        let functions = try LRFunctions(fields: sentence.fields)
        let replies = try LRFunctionReplies(fields: sentence.fields)
        return .init(uniqueKeysWithValues: zip(functions, replies))
      }
    }

    var time: Date? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply2]?.fields.datetime(
          ymdIndex: 2,
          hmsDecimalIndex: 3,
          optional: true
        )
      }
    }

    var shipName: String? {
      get throws(NMEAError) {
        guard let name = try sentences[.AISLongRangeReply1]?.fields.string(at: 3, optional: true)
        else {
          return nil
        }
        return Self.decoder.decode(string: name)
      }
    }

    var shipCallsign: String? {
      get throws(NMEAError) {
        guard
          let callsign = try sentences[.AISLongRangeReply1]?.fields.string(at: 4, optional: true)
        else {
          return nil
        }
        return Self.decoder.decode(string: callsign)
      }
    }

    var shipIMO: Int? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply1]?.fields.int(at: 5, optional: true)
      }
    }

    var position: Position? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply2]?.fields.position(
          latitudeIndex: (4, 5),
          longitudeIndex: (6, 7),
          optional: true
        )
      }
    }

    var course: Bearing? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply2]?.fields.bearing(
          at: 8,
          valueType: .float,
          referenceIndex: 9,
          optional: true
        )
      }
    }

    var speed: Measurement<UnitSpeed>? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply2]?.fields.measurement(
          at: 10,
          valueType: .float,
          unitAt: 11,
          units: speedUnits,
          optional: true
        )
      }
    }

    var destination: String? {
      get throws(NMEAError) {
        guard let dest = try sentences[.AISLongRangeReply3]?.fields.string(at: 2, optional: true)
        else {
          return nil
        }
        return Self.decoder.decode(string: dest)
      }
    }

    var ETA: Date? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.datetime(
          ymdIndex: 3,
          hmsDecimalIndex: 4,
          optional: true
        )
      }
    }

    var shipType: AISLongRange.ShipType? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.enumeration(
          at: 6,
          ofType: AISLongRange.ShipType.self,
          optional: true
        )
      }
    }

    var shipType2: AISLongRange.ShipType? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.enumeration(
          at: 9,
          ofType: AISLongRange.ShipType.self,
          optional: true
        )
      }
    }

    var length: Measurement<UnitLength>? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.measurement(
          at: 7,
          valueType: .float,
          units: UnitLength.meters,
          optional: true
        )
      }
    }

    var breadth: Measurement<UnitLength>? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.measurement(
          at: 8,
          valueType: .float,
          units: UnitLength.meters,
          optional: true
        )
      }
    }

    var draught: Measurement<UnitLength>? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.measurement(
          at: 5,
          valueType: .float,
          units: UnitLength.meters,
          optional: true
        )
      }
    }

    var soulsOnboard: Int? {
      get throws(NMEAError) {
        try sentences[.AISLongRangeReply3]?.fields.int(at: 10, optional: true)
      }
    }

    init?(sentence: ParametricSentence) throws(NMEAError) {
      switch sentence.format {
        case .AISLongRangeFunction:
          let functions = try LRFunctions(fields: sentence.fields)
          formats = .init(
            [.AISLongRangeFunction] + functions.compactMap { Self.functionFormats[$0] }
          )
        case .AISLongRangeReply1, .AISLongRangeReply2, .AISLongRangeReply3:
          formats = Set()
        default:
          fatalError("Unexpected sentence format")
      }

      sentences[sentence.format] = sentence
    }

    mutating func append(_ other: Self) throws(LRFErrors) {
      for (format, sentence) in other.sentences {
        guard sentences[format] == nil else { throw .formatAlreadySeen }
        sentences[format] = sentence
      }
      formats.formUnion(other.formats)

      // if we receive an LR1/LR2/LR3 that we weren't expecting based on the previous LRF...
      if !formats.isEmpty && !Set(sentences.keys).subtracting(formats).isEmpty {
        throw LRFErrors.unexpectedFormat
      }
    }
  }

  private class LRFBuffer: Buffer {
    typealias Recipient = LRFRecipient
    typealias Element = LRFElement

    var buffer = [Recipient: Element]()
  }

  private enum LRFErrors: Error {
    case formatAlreadySeen
    case unexpectedFormat
  }
}

func LRFunctions(fields: Fields) throws(NMEAError) -> [AISLongRange.Function] {
  let functionStr = try fields.string(at: 3, optional: false)!
  var functions = [AISLongRange.Function]()
  for char in functionStr {
    guard let function = AISLongRange.Function(rawValue: char) else {
      throw fields.fieldError(type: .badCharacterValue, index: 2)
    }
    functions.append(function)
  }
  return functions
}

private func LRFunctionReplies(fields: Fields) throws(NMEAError)
  -> [AISLongRange.FunctionStatus]
{
  let replyStr = try fields.string(at: 4, optional: false)!
  var statuses = [AISLongRange.FunctionStatus]()
  for char in replyStr {
    guard let rawValue = Int(String(char)),
      let status = AISLongRange.FunctionStatus(rawValue: rawValue)
    else {
      throw fields.fieldError(type: .badCharacterValue, index: 2)
    }
    statuses.append(status)
  }
  return statuses
}
