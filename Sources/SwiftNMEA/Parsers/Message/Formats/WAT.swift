import Collections
import Foundation
import NMEAUnits

class WATParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .waterLevel
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let type = try sentence.fields.enumeration(at: 0, ofType: Doors.MessageType.self)!
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)
    let alarmType = try sentence.fields.enumeration(at: 2, ofType: WaterSensor.SystemType.self)!
    let location1 = try sentence.fields.string(at: 3, optional: true)
    let location2 = try sentence.fields.string(at: 4, optional: true)
    let number = try sentence.fields.int(at: 5, optional: true)
    let condition = try sentence.fields.enumeration(
      at: 6,
      ofType: WaterSensor.Status.self,
      optional: true
    )
    let overriden = try sentence.fields.bool(at: 7, trueValue: "O", falseValue: "N", optional: true)
    let message = try sentence.fields.string(at: 8, optional: true)

    return .waterLevel(
      messageType: type,
      time: time,
      systemType: alarmType,
      location1: location1,
      location2: location2,
      number: number,
      alarmCondition: condition,
      isOverriden: overriden,
      description: message
    )
  }
}
