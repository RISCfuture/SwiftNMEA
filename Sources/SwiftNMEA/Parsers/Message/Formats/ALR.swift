import Foundation

class ALRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alarmState
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let identifier = try sentence.fields.int(at: 1)!
    let condition = try sentence.fields.bool(at: 2)!
    let state = try sentence.fields.bool(at: 3)!
    let description = try sentence.fields.string(at: 4, optional: true)

    return .alarmState(
      changeTime: time,
      identifier: identifier,
      thresholdExceeded: condition,
      acknowledged: state,
      description: description
    )
  }
}
