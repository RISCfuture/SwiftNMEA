import Foundation
import NMEAUnits

class MWVParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .windAngleSpeed
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let angle = try sentence.fields.measurement(at: 0, valueType: .float, units: UnitAngle.degrees)!
    let reference = try sentence.fields.enumeration(at: 1, ofType: RelativeWindReference.self)!
    let speed = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 3,
      units: speedUnits
    )!
    let status = try sentence.fields.bool(at: 4)!

    return .windAngleSpeed(angle: angle, speed: speed, reference: reference, isValid: status)
  }
}
