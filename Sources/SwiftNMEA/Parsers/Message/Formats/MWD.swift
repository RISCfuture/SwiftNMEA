import Foundation
import NMEAUnits

class MWDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .windDirectionSpeed
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let directionTrue = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!
    let directionMag = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!
    let speedKts = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 5,
      units: speedUnits
    )!
    let speedMps = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      unitAt: 7,
      units: speedUnits
    )!

    return .windDirectionSpeed(
      directionTrue: directionTrue,
      directionMagnetic: directionMag,
      speedKnots: speedKts,
      speedMps: speedMps
    )
  }
}
