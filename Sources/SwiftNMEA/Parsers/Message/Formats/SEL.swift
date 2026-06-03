import Foundation

class SELParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .dataSelection
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    var selections = [Selection.DataID: String?]()
    for index in stride(from: 0, to: sentence.fields.count, by: 2) {
      let dataID = try sentence.fields.enumeration(at: index, ofType: Selection.DataID.self)!
      // The System Function ID (SFI) of the selected sensor is nullable
      // (comment 2): a null field indicates the data is from the SEL source.
      let sourceSFI = try sentence.fields.string(at: index + 1, optional: true)
      // a given data type may only appear once per sentence
      guard selections.updateValue(sourceSFI, forKey: dataID) == nil else {
        throw sentence.fields.fieldError(type: .badValue, index: index)
      }
    }

    return .dataSelection(selections)
  }
}
