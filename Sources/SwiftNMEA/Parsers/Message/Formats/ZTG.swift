import Collections
import Foundation

class ZTGParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .timeToDestination
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let observation = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let time = try sentence.fields.hmsDecimalDuration(at: 1)!
    let id = try sentence.fields.string(at: 2)!

    return .timeToDestination(observation: observation, timeToGo: time, destinationID: id)
  }
}
