import Collections
import Foundation
import NMEAUnits

class WCVParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .waypointClosure
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let closure = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: speedUnits
    )!
    let identifier = try sentence.fields.string(at: 2)!
    let mode = try sentence.fields.enumeration(at: 3, ofType: Navigation.Mode.self)!

    return .waypointClosure(closure, identifier: identifier, mode: mode)
  }
}
