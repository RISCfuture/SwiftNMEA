import Foundation

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
    let center = try sentence.fields.float(at: 5, optional: true)
    let centerValid = try sentence.fields.bool(at: 6, optional: true)
    let bow = try sentence.fields.float(at: 7, optional: true)
    let bowValid = try sentence.fields.bool(at: 8, optional: true)

    // Footnote 2: if a rudder order field is not null, the corresponding status
    // field shall not be null.
    if port != nil, portValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
    }
    if center != nil, centerValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 6)
    }
    if bow != nil, bowValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 8)
    }

    return .rudderOrder(
      starboard: starboard,
      port: port,
      starboardValid: starboardValid,
      portValid: portValid,
      commandSource: source,
      center: center,
      centerValid: centerValid,
      bow: bow,
      bowValid: bowValid
    )
  }
}
