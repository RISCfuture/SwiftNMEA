import Foundation

class HCRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .headingCorrectionReport
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heading = try sentence.fields.bearing(at: 0, valueType: .float, reference: .true)!
    let mode = try sentence.fields.enumeration(at: 1, ofType: Heading.Mode.self)!
    let correctionState = try sentence.fields.enumeration(
      at: 2,
      ofType: Heading.CorrectionState.self
    )!
    let correctionValue = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitAngle.degrees,
      optional: true
    )

    return .headingCorrectionReport(
      heading,
      mode: mode,
      correctionState: correctionState,
      correctionValue: correctionValue
    )
  }
}
