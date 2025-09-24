import Foundation

class HSSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .hullStress
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let point = try sentence.fields.string(at: 0)!
    let value = try sentence.fields.float(at: 1)!
    let status = try sentence.fields.bool(at: 2)!

    return .hullStress(value, point: point, isValid: status)
  }
}
