import Foundation

class AKDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .detailAlarmAcknowledgement
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true)
    let sourceSystem = try sentence.fields.string(at: 1)!
    let sourceSubsystem = try sentence.fields.string(at: 2, optional: true)
    let sourceInstance = try sentence.fields.int(at: 3)!
    let sourceType = try sentence.fields.int(at: 4)!
    let acknowledgingSystem = try sentence.fields.string(at: 5, optional: true)
    let acknowledgingSubsystem = try sentence.fields.string(at: 6, optional: true)
    let acknowledgingInstance = try sentence.fields.int(at: 7, optional: true)

    guard
      let sourceAlarm = Alarm(system: sourceSystem, subsystem: sourceSubsystem, type: sourceType)
    else {
      throw sentence.fields.lineError(type: .badValue)
    }
    let acknowledgingAlarmSystem = acknowledgingSystem.flatMap { system in
      AlarmSystem(system: system, subsystem: acknowledgingSubsystem)
    }

    return .detailAlarmAcknowledgement(
      time: time,
      alarm: sourceAlarm,
      instance: sourceInstance,
      sender: acknowledgingAlarmSystem,
      senderInstance: acknowledgingInstance
    )
  }
}
