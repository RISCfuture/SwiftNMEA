import Foundation

class DORParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .doorStatus
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let messageType = try sentence.fields.enumeration(at: 0, ofType: Doors.MessageType.self)!
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)
    let systemType = try sentence.fields.enumeration(at: 2, ofType: Doors.SystemType.self)!
    let division1 = try sentence.fields.string(at: 3, optional: true)
    let division2 = try sentence.fields.string(at: 4, optional: true)
    let doorNumber = try sentence.fields.int(at: 5, optional: true)
    let status = try sentence.fields.enumeration(at: 6, ofType: Doors.Status.self, optional: true)
    let switchSetting = try sentence.fields.enumeration(
      at: 7,
      ofType: Doors.SwitchSetting.self,
      optional: true
    )
    let description = try sentence.fields.string(at: 8, optional: true)

    return .doorStatus(
      messageType: messageType,
      time: time,
      systemType: systemType,
      division1: division1,
      division2: division2,
      doorNumber: doorNumber,
      doorStatus: status,
      switchSetting: switchSetting,
      description: description
    )
  }
}
