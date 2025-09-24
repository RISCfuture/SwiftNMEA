import Foundation
import NMEAUnits

class THSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .trueHeadingMode
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let heading = try sentence.fields.bearing(at: 0, valueType: .float, reference: .true)!
    let mode = try sentence.fields.enumeration(at: 1, ofType: Heading.Mode.self)!

    return .trueHeadingMode(heading, mode: mode)
  }
}
