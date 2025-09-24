import Collections
import Foundation
import NMEAUnits

class ZDLParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .timeDistanceToVariablePoint
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimalDuration(at: 0)!
    let distance = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitLength.nauticalMiles
    )!
    let type = try sentence.fields.enumeration(at: 2, ofType: Navigation.VariablePoint.self)!

    return .timeDistanceToVariablePoint(
      time: time,
      distance: distance,
      type: type
    )
  }
}
