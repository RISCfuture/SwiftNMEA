import Foundation
import NMEAUnits

class OSDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .ownshipData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heading = try sentence.fields.bearing(at: 0, valueType: .float, reference: .true)!
    let headingStatus = try sentence.fields.bool(at: 1)!
    let course = try sentence.fields.bearing(at: 2, valueType: .float, reference: .true)!
    let courseRef = try sentence.fields.enumeration(at: 3, ofType: CourseSpeedReference.self)!
    let speed = try sentence.fields.measurement(
      at: 4, valueType: .float, unitAt: 8, units: speedUnits)!
    let speedRef = try sentence.fields.enumeration(at: 5, ofType: CourseSpeedReference.self)!
    let set = try sentence.fields.bearing(at: 6, valueType: .float, reference: .true)!
    let drift = try sentence.fields.measurement(
      at: 7, valueType: .float, unitAt: 8, units: speedUnits)!

    return .ownshipData(
      heading: heading,
      headingValid: headingStatus,
      course: course,
      courseReference: courseRef,
      speed: speed,
      speedReference: speedRef,
      set: set,
      drift: drift)
  }
}
