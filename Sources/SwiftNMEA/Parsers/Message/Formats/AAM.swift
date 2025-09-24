import Foundation

class AAMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .waypointArrivalAlarm
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let arrivalCircleEntered = try sentence.fields.bool(at: 0)!
    let perpendicularPassed = try sentence.fields.bool(at: 1)!
    let radius = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 3,
      units: lengthUnits
    )!
    let waypointID = try sentence.fields.string(at: 4)!

    return .waypointArrivalAlarm(
      arrivalCircleEntered: arrivalCircleEntered,
      perpendicularPassed: perpendicularPassed,
      arrivalCircleRadius: radius,
      waypoint: waypointID
    )
  }
}
