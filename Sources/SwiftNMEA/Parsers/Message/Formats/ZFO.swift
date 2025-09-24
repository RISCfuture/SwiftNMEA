import Collections
import Foundation
import NMEAUnits

class ZFOParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .timeFromOrigin
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let observation = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let time = try sentence.fields.hmsDecimalDuration(at: 1)!
    let id = try sentence.fields.string(at: 2)!

    return .timeFromOrigin(observation: observation, elapsedTime: time, originID: id)
  }
}
