import Foundation

class GRSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSRangeResiduals
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let mode = try sentence.fields.bool(at: 1, trueValue: "1", falseValue: "0")!
    let signalID = try sentence.fields.int(at: sentence.fields.endIndex - 1)!
    let systemID = try sentence.fields.int(at: sentence.fields.endIndex - 2)!
    let residuals: [GNSS.SatelliteID: Measurement<UnitLength>] = try
      (2..<(sentence.fields.endIndex - 2)).reduce(into: [:]) { dict, index in
        do {
          let id = try GNSS.SatelliteID(systemID: systemID, svID: index - 2, signalID: signalID)
          let residual = try sentence.fields.measurement(
            at: index,
            valueType: .float,
            units: UnitLength.meters
          )!
          dict[id] = residual
        } catch let error as GNSS.SatelliteID.Errors {
          switch error {
            case .badSignalID:
              throw sentence.fields.fieldError(
                type: .unknownValue,
                index: sentence.fields.endIndex - 1
              )
            case .badSystemID:
              throw sentence.fields.fieldError(
                type: .unknownValue,
                index: sentence.fields.endIndex - 2
              )
            default:
              fatalError("Did not expect \(error)")
          }
        }
      }

    return .GNSSRangeResiduals(residuals, time: time, recomputed: mode)
  }
}
