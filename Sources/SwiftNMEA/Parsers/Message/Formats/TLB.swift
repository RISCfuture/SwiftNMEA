import Foundation

class TLBParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .targetLabels
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    var labels = [Int: String?]()
    for index in stride(from: 0, to: sentence.fields.count, by: 2) {
      let target = try sentence.fields.int(at: index)!
      let label = try sentence.fields.string(at: index + 1, optional: true)
      // a target number may only appear once per sentence
      guard labels.updateValue(label, forKey: target) == nil else {
        throw sentence.fields.fieldError(type: .badValue, index: index)
      }
    }

    return .targetLabels(labels)
  }
}
