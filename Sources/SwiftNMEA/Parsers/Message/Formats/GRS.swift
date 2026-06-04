import Foundation

class GRSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSRangeResiduals
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let mode = try sentence.fields.bool(at: 1, trueValue: "1", falseValue: "0")!
    // Residuals occupy the fields between the time/mode header and the trailing
    // System ID / Signal ID; too few fields means those required values are
    // missing. Guard before reading the trailing fields so a too-short sentence
    // reports the missing values rather than misparsing the header as hex.
    let residualsEnd = sentence.fields.endIndex - 2
    guard residualsEnd >= 2 else {
      throw sentence.fields.lineError(type: .missingRequiredValue)
    }
    // System ID and Signal ID are hex ('h') fields; Signal ID reaches A–F
    guard
      let signalID = Int(
        exactly: try sentence.fields.hex(at: sentence.fields.endIndex - 1, width: nil)!
      )
    else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: sentence.fields.endIndex - 1)
    }
    guard
      let systemID = Int(
        exactly: try sentence.fields.hex(at: sentence.fields.endIndex - 2, width: nil)!
      )
    else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: sentence.fields.endIndex - 2)
    }
    let residuals: [GNSS.SatelliteID: Measurement<UnitLength>] = try (2..<residualsEnd).reduce(
      into: [:]) { dict, index in
        do {
          let id = try GNSS.SatelliteID(systemID: systemID, svID: index - 2, signalID: signalID)
          // unused satellite slots are null fields; omit them from the dictionary
          guard
            let residual = try sentence.fields.measurement(
              at: index,
              valueType: .float,
              units: UnitLength.meters,
              optional: true
            )
          else { return }
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
