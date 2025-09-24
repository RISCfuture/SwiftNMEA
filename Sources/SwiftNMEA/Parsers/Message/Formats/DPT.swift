import Foundation

class DPTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .depth
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let depth = try sentence.fields.measurement(at: 0, valueType: .float, units: UnitLength.meters)!
    let offset = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitLength.meters
    )!
    let maxRange = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitLength.meters
    )!

    return .depth(
      depth,
      offset: offset,
      maxRange: maxRange
    )
  }
}
