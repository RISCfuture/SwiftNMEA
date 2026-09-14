import Foundation

class HBTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .heartbeat
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let interval = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      units: UnitDuration.seconds,
      optional: true
    )
    let isNormal = try sentence.fields.bool(at: 1)!
    let sequenceNumber = try sentence.fields.int(at: 2)!

    return .heartbeat(interval: interval, isNormal: isNormal, sequenceNumber: sequenceNumber)
  }
}
