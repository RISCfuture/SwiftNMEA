import Foundation

class OSDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .ownshipData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heading = try sentence.fields.bearing(
      at: 0,
      valueType: .float,
      reference: .true,
      optional: true
    )
    let headingStatus = try sentence.fields.bool(at: 1)!
    let course = try sentence.fields.bearing(
      at: 2,
      valueType: .float,
      reference: .true,
      optional: true
    )
    let courseRef = try sentence.fields.enumeration(
      at: 3,
      ofType: CourseSpeedReference.self,
      optional: true
    )
    let speed = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 8,
      units: speedUnits,
      optional: true
    )
    let speedRef = try sentence.fields.enumeration(
      at: 5,
      ofType: CourseSpeedReference.self,
      optional: true
    )
    let set = try sentence.fields.bearing(
      at: 6,
      valueType: .float,
      reference: .true,
      optional: true
    )
    let drift = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      unitAt: 8,
      units: speedUnits,
      optional: true
    )

    return .ownshipData(
      heading: heading,
      headingValid: headingStatus,
      course: course,
      courseReference: courseRef,
      speed: speed,
      speedReference: speedRef,
      set: set,
      drift: drift
    )
  }
}
