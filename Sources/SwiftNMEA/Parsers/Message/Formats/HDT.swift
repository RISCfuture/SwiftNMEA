import Foundation

class HDTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .trueHeading
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heading = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!
    return .trueHeading(heading)
  }
}
