import Foundation

class HRMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .heelRollMeasurement
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heelAngle = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      units: UnitAngle.degrees
    )!
    let rollPeriod = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitDuration.seconds
    )!
    let rollAmplitudePort = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitAngle.degrees
    )!
    let rollAmplitudeStarboard = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitAngle.degrees
    )!
    let isValid = try sentence.fields.bool(at: 4)!
    let peakHoldPort = try sentence.fields.measurement(
      at: 5,
      valueType: .float,
      units: UnitAngle.degrees,
      optional: true
    )
    let peakHoldStarboard = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      units: UnitAngle.degrees,
      optional: true
    )
    let peakHoldResetTime = try sentence.fields.datetime(
      ymdIndex: (10, 9, 8),
      hmsIndex: 7,
      optional: true
    )
    let alertThreshold = try sentence.fields.measurement(
      at: 11,
      valueType: .float,
      units: UnitAngle.degrees,
      optional: true
    )
    let status = try sentence.fields.enumeration(at: 12, ofType: SentenceType.self)!

    return .heelRollMeasurement(
      heelAngle: heelAngle,
      rollPeriod: rollPeriod,
      rollAmplitudePort: rollAmplitudePort,
      rollAmplitudeStarboard: rollAmplitudeStarboard,
      isValid: isValid,
      peakHoldPort: peakHoldPort,
      peakHoldStarboard: peakHoldStarboard,
      peakHoldResetTime: peakHoldResetTime,
      alertThreshold: alertThreshold,
      status: status
    )
  }
}
