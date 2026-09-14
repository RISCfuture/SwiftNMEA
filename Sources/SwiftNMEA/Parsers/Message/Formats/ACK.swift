import Foundation

class ACKParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alarmAcknowledgement
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let identifier = try sentence.fields.int(at: 0)!
    return .alarmAcknowledgement(identifier: identifier)
  }
}
