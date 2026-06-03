import Foundation

class MOBParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .manOverboard
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let emitterID = try sentence.fields.hex(at: 0, width: 5, optional: true)
    let status = try sentence.fields.enumeration(at: 1, ofType: ManOverboard.Status.self)!
    let activationTime = try sentence.fields.hmsDecimal(at: 2, searchDirection: .backward)!
    let positionSource = try sentence.fields.enumeration(
      at: 3,
      ofType: ManOverboard.PositionSource.self
    )!

    let daysValue = try sentence.fields.int(at: 4)!
    guard daysValue >= 0 else { throw sentence.fields.fieldError(type: .badValue, index: 4) }
    let daysSinceActivation = UInt(daysValue)

    let positionTime = try sentence.fields.hmsDecimal(at: 5, searchDirection: .backward)!
    let position = try sentence.fields.position(latitudeIndex: (6, 7), longitudeIndex: (8, 9))!
    let courseOverGround = try sentence.fields.bearing(
      at: 10,
      valueType: .integer,
      reference: .true
    )!
    let speedOverGround = try sentence.fields.measurement(
      at: 11,
      valueType: .integer,
      units: UnitSpeed.knots
    )!
    let MMSI = try sentence.fields.int(at: 12, optional: true)
    let batteryStatus = try sentence.fields.enumeration(
      at: 13,
      ofType: ManOverboard.BatteryStatus.self,
      optional: true
    )

    return .manOverboard(
      emitterID: emitterID,
      status: status,
      activationTime: activationTime,
      positionSource: positionSource,
      daysSinceActivation: daysSinceActivation,
      positionTime: positionTime,
      position: position,
      courseOverGround: courseOverGround,
      speedOverGround: speedOverGround,
      MMSI: MMSI,
      batteryStatus: batteryStatus
    )
  }
}
