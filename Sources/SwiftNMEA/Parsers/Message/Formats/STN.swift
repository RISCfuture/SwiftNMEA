import Foundation

class STNParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .talkerID
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let talkerID = try sentence.fields.int(at: 0)!
    return .talkerID(talkerID)
  }
}
