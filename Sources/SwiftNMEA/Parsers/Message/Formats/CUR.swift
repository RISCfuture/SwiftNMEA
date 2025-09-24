import Foundation

class CURParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .currentWaterLayer
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let validity = try sentence.fields.bool(at: 0)!
    let set = try sentence.fields.int(at: 1)!
    let layer = try sentence.fields.int(at: 2)!
    let depth = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!
    let direction = try sentence.fields.bearing(at: 4, valueType: .float, referenceIndex: 5)!
    let speed = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitSpeed.knots)!
    let referenceDepth = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      units: UnitLength.meters
    )!
    let heading = try sentence.fields.bearing(at: 8, valueType: .float, referenceIndex: 9)!
    let speedReference = try sentence.fields.enumeration(
      at: 10,
      ofType: WaterSensor.SpeedReference.self
    )!

    return .currentWaterLayer(
      isValid: validity,
      setNumber: set,
      layer: layer,
      depth: depth,
      direction: direction,
      speed: speed,
      referenceDepth: referenceDepth,
      heading: heading,
      speedReference: speedReference
    )
  }
}
