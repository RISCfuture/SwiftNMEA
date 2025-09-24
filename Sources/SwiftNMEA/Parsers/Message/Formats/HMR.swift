import Foundation

class HMRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .headingMonitorReceive
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let sensor1ID = try sentence.fields.string(at: 0)!
    let sensor2ID = try sentence.fields.string(at: 1)!
    let setDifference = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitAngle.degrees
    )!
    let difference = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitAngle.degrees
    )!
    let warning = try sentence.fields.bool(at: 4)!
    let heading1 = try sentence.fields.bearing(at: 5, valueType: .float, referenceIndex: 7)!
    let valid1 = try sentence.fields.bool(at: 6)!
    let deviation1 = try sentence.fields.deviation(at: (8, 9), valueType: .float, optional: true)
    let heading2 = try sentence.fields.bearing(at: 10, valueType: .float, referenceIndex: 12)!
    let valid2 = try sentence.fields.bool(at: 11)!
    let deviation2 = try sentence.fields.deviation(at: (13, 14), valueType: .float, optional: true)
    let variation = try sentence.fields.deviation(at: (15, 16), valueType: .float, optional: true)

    let sensor1 = HeadingSensor(
      id: sensor1ID,
      heading: heading1,
      isValid: valid1,
      deviation: deviation1
    )
    let sensor2 = HeadingSensor(
      id: sensor2ID,
      heading: heading2,
      isValid: valid2,
      deviation: deviation2
    )

    return .headingMonitorReceive(
      sensor1: sensor1,
      sensor2: sensor2,
      setDifference: setDifference,
      difference: difference,
      differenceOK: warning,
      variation: variation
    )
  }
}
