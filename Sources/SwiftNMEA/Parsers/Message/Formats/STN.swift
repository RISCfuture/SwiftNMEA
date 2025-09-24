import Foundation
import NMEAUnits

class STNParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .talkerID
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let talkerID = try sentence.fields.int(at: 0)!
    return .talkerID(talkerID)
  }
}
