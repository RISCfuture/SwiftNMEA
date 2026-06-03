import Foundation

class VBCParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .dockingSpeedData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let waterLongitudinal = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterBowTransverse = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterTransverse = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterSternTransverse = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let waterValid = try sentence.fields.bool(at: 4)!
    let groundLongitudinal = try sentence.fields.measurement(
      at: 5,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundBowTransverse = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundTransverse = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundSternTransverse = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let groundValid = try sentence.fields.bool(at: 9)!

    let water = DockingSpeedVector(
      longitudinal: waterLongitudinal,
      bowTransverse: waterBowTransverse,
      transverse: waterTransverse,
      sternTransverse: waterSternTransverse
    )
    let ground = DockingSpeedVector(
      longitudinal: groundLongitudinal,
      bowTransverse: groundBowTransverse,
      transverse: groundTransverse,
      sternTransverse: groundSternTransverse
    )

    return .dockingSpeedData(
      water: water,
      waterValid: waterValid,
      ground: ground,
      groundValid: groundValid
    )
  }
}
