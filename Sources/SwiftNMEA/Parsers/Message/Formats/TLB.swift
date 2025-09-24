import Collections
import Foundation
import NMEAUnits

class TLBParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .targetLabels
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let labels = [Int: String?](
      uniqueKeysWithValues: try stride(from: 0, to: sentence.fields.count, by: 2)
        .compactMap { index in
          let target = try sentence.fields.int(at: index)!
          let label = try sentence.fields.string(at: index + 1, optional: true)
          return (target, label)
        }
    )

    return .targetLabels(labels)
  }
}
