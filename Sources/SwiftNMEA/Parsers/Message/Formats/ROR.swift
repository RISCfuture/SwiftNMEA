import Foundation
import NMEAUnits

class RORParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .rudderOrder
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let starboard = try sentence.fields.float(at: 0)!
    let starboardValid = try sentence.fields.bool(at: 1)!
    let port = try sentence.fields.float(at: 2, optional: true)
    let portValid = try sentence.fields.bool(at: 3, optional: true)
    let source = try sentence.fields.enumeration(at: 4, ofType: Propulsion.Location.self)!

    return .rudderOrder(
      starboard: starboard,
      port: port,
      starboardValid: starboardValid,
      portValid: portValid,
      commandSource: source
    )
  }
}
