import Foundation

class EVEParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .event
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true)
    let tag = try sentence.fields.string(at: 1, optional: true)
    let description = try sentence.fields.string(at: 2)!

    return .event(time: time, tag: tag, description: description)
  }
}
