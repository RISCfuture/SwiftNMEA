import Foundation

class MTWParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .waterTemperature
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let temp = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: temperatureUnits
    )!

    return .waterTemperature(temp)
  }
}
