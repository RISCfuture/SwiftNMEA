import Collections
import Foundation
import NMEAUnits

class XTEParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .crossTrackError
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let blink = try sentence.fields.bool(at: 0, trueValue: "V", falseValue: "A")!
    let cycleLock = try sentence.fields.bool(at: 1, trueValue: "V", falseValue: "A")!
    let xte = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 4,
      units: lengthUnits
    )!
    let isLeft = try sentence.fields.bool(at: 3, trueValue: "L", falseValue: "R")!
    let mode = try sentence.fields.enumeration(at: 5, ofType: Navigation.Mode.self)!

    return .crossTrackError(
      isLeft ? xte * -1 : xte,
      mode: mode,
      LORANC_blinkSNRFlag: blink,
      LORANC_cycleLockWarningFlag: cycleLock
    )
  }
}
