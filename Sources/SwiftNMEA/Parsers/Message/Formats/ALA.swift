import Foundation

class ALAParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .detailAlarm
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true)
    let system = try sentence.fields.string(at: 1)!
    let subsystem = try sentence.fields.string(at: 2, optional: true)
    let instance = try sentence.fields.int(at: 3)!
    let type = try sentence.fields.int(at: 4)!
    let condition = try sentence.fields.enumeration(at: 5, ofType: AlarmCondition.self)!
    let state = try sentence.fields.enumeration(at: 6, ofType: AlarmAcknowledgementState.self)!
    let description = try sentence.fields.string(at: 7, optional: true)

    guard let alarm = Alarm(system: system, subsystem: subsystem, type: type) else {
      throw sentence.fields.lineError(type: .badValue)
    }

    return .detailAlarm(
      time: time,
      alarm: alarm,
      instance: instance,
      condition: condition,
      acknowledgementState: state,
      description: description
    )
  }
}
