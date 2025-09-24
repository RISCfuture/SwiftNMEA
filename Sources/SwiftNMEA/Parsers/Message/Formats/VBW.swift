import Foundation
import NMEAUnits

class VBWParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .speedData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let waterSpeedLon = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterSpeedTr = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterSpeedValid = try sentence.fields.bool(at: 2)!
    let groundSpeedLon = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundSpeedTr = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundSpeedValid = try sentence.fields.bool(at: 5)!
    let sternWaterSpeed = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let sternWaterSpeedValid = try sentence.fields.bool(at: 7)!
    let sternGroundSpeed = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let sternGroundSpeedValid = try sentence.fields.bool(at: 9)!

    let waterSpeed = SpeedVector(longitudinal: waterSpeedLon, transverse: waterSpeedTr)
    let groundSpeed = SpeedVector(longitudinal: groundSpeedLon, transverse: groundSpeedTr)

    return .speedData(
      water: waterSpeed,
      waterValid: waterSpeedValid,
      ground: groundSpeed,
      groundValid: groundSpeedValid,
      sternTransverseWater: sternWaterSpeed,
      sternTransverseWaterValid: sternWaterSpeedValid,
      sternTransverseGround: sternGroundSpeed,
      sternTransverseGroundValid: sternGroundSpeedValid
    )
  }
}
