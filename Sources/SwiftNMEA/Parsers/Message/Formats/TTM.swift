import Collections
import Foundation
import NMEAUnits

class TTMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .trackedTarget
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let number = try sentence.fields.int(at: 0)!
    let distance = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      unitAt: 9,
      units: lengthUnits
    )!
    let bearing = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!
    let speed = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 9,
      units: speedUnits
    )!
    let course = try sentence.fields.bearing(at: 5, valueType: .float, referenceIndex: 6)!
    let CPADistance = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      unitAt: 9,
      units: lengthUnits
    )!
    let CPATime = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      units: UnitDuration.minutes
    )!
    let name = try sentence.fields.string(at: 10)!
    let status = try sentence.fields.enumeration(at: 11, ofType: Radar.TargetStatus.self)!
    let isReference = try sentence.fields.character(at: 12) == "R"
    let time = try sentence.fields.hmsDecimal(at: 13, searchDirection: .backward)!
    let acquisition = try sentence.fields.enumeration(at: 14, ofType: Radar.AcquisitionType.self)!

    return .trackedTarget(
      number: number,
      distance: distance,
      bearing: bearing,
      speed: speed,
      course: course,
      CPADistance: CPADistance,
      CPATime: CPATime,
      name: name,
      status: status,
      isReference: isReference,
      time: time,
      acquisition: acquisition
    )
  }
}
