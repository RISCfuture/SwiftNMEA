import Foundation

class SLMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .steeringLocationMode
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let systemStatus = try sentence.fields.enumeration(
      at: 0,
      ofType: SteeringLocationMode.SystemStatus.self
    )!
    let location = try sentence.fields.enumeration(
      at: 1,
      ofType: SteeringLocationMode.Location.self
    )!
    let locationDescription = try sentence.fields.string(at: 2, optional: true)
    let mode = try sentence.fields.enumeration(at: 3, ofType: SteeringLocationMode.Mode.self)!
    let subMode = try sentence.fields.string(at: 4, optional: true)

    if location == .others, locationDescription == nil {
      throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
    }

    return .steeringLocationMode(
      systemStatus: systemStatus,
      location: location,
      locationDescription: locationDescription,
      mode: mode,
      subMode: subMode
    )
  }
}
