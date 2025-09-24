import Foundation
import NMEAUnits

class RMCParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSMinimumData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.datetime(ymdIndex: 8, hmsDecimalIndex: 0)!
    let isValid = try sentence.fields.bool(at: 1)!
    let position = try sentence.fields.position(latitudeIndex: (2, 3), longitudeIndex: (4, 5))!
    let speed = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitSpeed.knots)!
    let course = try sentence.fields.bearing(at: 7, valueType: .float, reference: .true)!
    let variation = try sentence.fields.deviation(at: (9, 10), valueType: .float)!
    let mode = try sentence.fields.enumeration(at: 11, ofType: Navigation.Mode.self)!
    let status = try sentence.fields.enumeration(at: 12, ofType: GNSS.IntegrityStatus.self)!

    return .GNSSMinimumData(
      time: time,
      isValid: isValid,
      position: position,
      speed: speed,
      course: course,
      magneticVariation: variation,
      mode: mode,
      status: status
    )
  }
}
