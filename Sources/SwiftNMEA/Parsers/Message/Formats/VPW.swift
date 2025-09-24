import Collections
import Foundation
import NMEAUnits

class VPWParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .speedParallelToWind
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let knots = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: speedUnits
    )!
    let mps = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 3,
      units: speedUnits
    )!

    return .speedParallelToWind(knots: knots, mps: mps)
  }
}
