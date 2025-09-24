import Foundation
import NMEAUnits

class RPMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .revolutions
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let source = try sentence.fields.enumeration(at: 0, ofType: Propulsion.ThrustSource.self)!
    let number = try sentence.fields.int(at: 1)!
    let speed = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitAngularVelocity.revolutionsPerMinute
    )!
    let pitch = try sentence.fields.float(at: 3)!
    let isValid = try sentence.fields.bool(at: 4)!

    return .revolutions(
      source: source,
      number: number,
      speed: speed,
      pitch: pitch,
      isValid: isValid
    )
  }
}
