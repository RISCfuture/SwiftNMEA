import Foundation

class DBTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .depthBelowTransducer
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let feet = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: lengthUnits
    )!
    let meters = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 3,
      units: lengthUnits
    )!
    let fathoms = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 5,
      units: lengthUnits
    )!

    return .depthBelowTransducer([feet, meters, fathoms])
  }
}
