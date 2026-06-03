import Foundation

class GDCParser: MessageFormat {
  private var buffer = SentenceCountingBuffer<Recipient, BufferElement>()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSDifferentialCorrection
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalSentences = try sentence.fields.int(at: 0)!
    let sentenceNumber = try sentence.fields.int(at: 1)!
    let totalSatellites = try sentence.fields.int(at: 2)!
    let satelliteNum = try sentence.fields.int(at: 3)!
    let pseudorangeCorrection = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      units: UnitLength.meters
    )!
    let issueOfData = try sentence.fields.int(at: 5)!
    let epochTime = try sentence.fields.measurement(
      at: 6,
      valueType: .integer,
      units: UnitDuration.seconds
    )!
    let modifiedZCount = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      units: UnitDuration.seconds
    )!
    let UDRE = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      units: UnitLength.meters
    )!
    // Signal ID is a hex ('h') field reaching A–F; the System is identified by
    // the talker (GP/GL/GA/GB/GQ/GI), not the satellite ID range. Talker GN is
    // not permitted by the specification.
    guard let signalID = Int(exactly: try sentence.fields.hex(at: 9, width: nil)!) else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 9)
    }

    guard let systemID = GNSS.systemID(forTalker: sentence.talker) else {
      throw sentence.fields.lineError(type: .unknownTalker)
    }

    let correction: GNSS.DifferentialCorrection
    do {
      let satelliteID = try GNSS.SatelliteID(
        systemID: systemID,
        svID: satelliteNum,
        signalID: signalID
      )
      correction = .init(
        satellite: satelliteID,
        pseudorangeCorrection: pseudorangeCorrection,
        issueOfData: issueOfData,
        epochTime: epochTime,
        modifiedZCount: modifiedZCount,
        UDRE: UDRE
      )
    } catch let error as GNSS.SatelliteID.Errors {
      switch error {
        case .badSignalID:
          throw sentence.fields.fieldError(type: .unknownValue, index: 9)
        case .badSvID:
          throw sentence.fields.fieldError(type: .unknownValue, index: 3)
        case .badSystemID:
          throw sentence.fields.lineError(type: .unknownTalker)
      }
    }

    let recipient = Recipient(talker: sentence.talker)
    let element = BufferElement(
      lastSentence: sentenceNumber,
      totalSentences: totalSentences,
      totalSatellites: totalSatellites,
      corrections: [correction]
    )

    do {
      return try buffer.add(element: element, for: recipient).map { finishedElement in
        makePayload(element: finishedElement)
      }
    } catch let error as BufferErrors {
      switch error {
        case .missingRecipient:
          throw sentence.fields.fieldError(type: .missingRequiredValue, index: 1)
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
      Message(
        talker: recipient.talker,
        format: recipient.format,
        payload: makePayload(element: element)
      )
    }
  }

  private func makePayload(element: BufferElement) -> Message.Payload {
    .GNSSDifferentialCorrection(element.corrections, totalSatellites: element.totalSatellites)
  }

  private struct Recipient: BufferRecipient {
    var talker: Talker
    var format: Format = .GNSSDifferentialCorrection
  }

  private struct BufferElement: SentenceCountingElement {
    var lastSentence: Int
    var totalSentences: Int
    var allSentences = Set<Int>()

    // written once
    var totalSatellites: Int

    // appended
    var corrections: [GNSS.DifferentialCorrection]

    mutating func append(payloadOnly other: GDCParser.BufferElement) {
      corrections.append(contentsOf: other.corrections)
    }
  }
}
