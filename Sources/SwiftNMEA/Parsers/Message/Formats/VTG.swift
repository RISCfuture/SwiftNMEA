import Collections
import Foundation
import NMEAUnits

class VTGParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .groundSpeedCourse
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let courseTrue = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!
    let courseMag = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!
    let speedKts = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 5,
      units: speedUnits
    )!
    let speedKph = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      unitAt: 7,
      units: speedUnits
    )!
    let mode = try sentence.fields.enumeration(at: 8, ofType: Navigation.Mode.self)!

    return .groundSpeedCourse(
      courseTrue: courseTrue,
      courseMagnetic: courseMag,
      speedKnots: speedKts,
      speedKph: speedKph,
      mode: mode
    )
  }
}
