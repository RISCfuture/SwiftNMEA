import Foundation

class HDTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .trueHeading
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let heading = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!
    return .trueHeading(heading)
  }
}
