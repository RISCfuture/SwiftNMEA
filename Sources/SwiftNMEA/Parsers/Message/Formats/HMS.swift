import Foundation

class HMSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .headingMonitorSet
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let sensor1ID = try sentence.fields.string(at: 0)!
    let sensor2ID = try sentence.fields.string(at: 1)!
    let maxDiff = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitAngle.degrees
    )!

    return .headingMonitorSet(
      sensor1: sensor1ID,
      sensor2: sensor2ID,
      maxDiff: maxDiff
    )
  }
}
