import Foundation

class GLLParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .geoPosition
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let position = try sentence.fields.position(latitudeIndex: (0, 1), longitudeIndex: (2, 3))!
    let time = try sentence.fields.hmsDecimal(at: 4, searchDirection: .backward)!
    let status = try sentence.fields.bool(at: 5)!
    let mode = try sentence.fields.enumeration(at: 6, ofType: Navigation.Mode.self)!

    return .geoPosition(position, time: time, isValid: status, mode: mode)
  }
}
