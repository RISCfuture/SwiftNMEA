import Collections
import Foundation

class XTRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .crossTrackErrorDR
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let xte = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 2,
      units: lengthUnits
    )!
    let isLeft = try sentence.fields.bool(at: 1, trueValue: "L", falseValue: "R")!

    return .crossTrackErrorDR(isLeft ? xte * -1 : xte)
  }
}
