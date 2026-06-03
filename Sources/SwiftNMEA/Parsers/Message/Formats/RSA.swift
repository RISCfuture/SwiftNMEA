import Foundation

class RSAParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .rudderSensorAngle
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let starboard = try sentence.fields.float(at: 0, optional: true)
    let starboardValid = try sentence.fields.bool(at: 1, optional: true)
    let port = try sentence.fields.float(at: 2, optional: true)
    let portValid = try sentence.fields.bool(at: 3, optional: true)
    let center = try sentence.fields.float(at: 4, optional: true)
    let centerValid = try sentence.fields.bool(at: 5, optional: true)
    let bowOrOther = try sentence.fields.float(at: 6, optional: true)
    let bowOrOtherValid = try sentence.fields.bool(at: 7, optional: true)

    // Comment 2: if a rudder sensor field is not null, the corresponding status
    // field shall not be null.
    if starboard != nil, starboardValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 1)
    }
    if port != nil, portValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
    }
    if center != nil, centerValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 5)
    }
    if bowOrOther != nil, bowOrOtherValid == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 7)
    }

    return .rudderSensorAngle(
      starboard: starboard,
      port: port,
      starboardValid: starboardValid,
      portValid: portValid,
      center: center,
      centerValid: centerValid,
      bowOrOther: bowOrOther,
      bowOrOtherValid: bowOrOtherValid
    )
  }
}
