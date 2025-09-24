import Foundation
import NMEAUnits

class MTWParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .waterTemperature
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let temp = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: temperatureUnits
    )!

    return .waterTemperature(temp)
  }
}
