import Foundation

class GBSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSFaultDetection
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let latitudeError = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitLength.meters
    )!
    let longitudeError = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitLength.meters
    )!
    let altitudeError = try sentence.fields.measurement(
      at: 3,
      valueType: .float,
      units: UnitLength.meters
    )!
    let satelliteNum = try sentence.fields.int(at: 4)!
    let missProbability = try sentence.fields.float(at: 5)!
    let biasEstimate = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      units: UnitLength.meters
    )!
    let standardDeviation = try sentence.fields.measurement(
      at: 7,
      valueType: .float,
      units: UnitLength.meters
    )!
    let systemID = try sentence.fields.int(at: 8)!
    let signalID = try sentence.fields.int(at: 9)!

    do {
      let satelliteID = try GNSS.SatelliteID(
        systemID: systemID,
        svID: satelliteNum,
        signalID: signalID
      )

      return .GNSSFaultDetection(
        time: time,
        latitudeError: latitudeError,
        longitudeError: longitudeError,
        altitudeError: altitudeError,
        failedSatellite: satelliteID,
        missProbability: missProbability,
        biasEstimate: biasEstimate,
        biasEstimateStddev: standardDeviation
      )
    } catch let error as GNSS.SatelliteID.Errors {
      switch error {
        case .badSignalID:
          throw sentence.fields.fieldError(type: .unknownValue, index: 9)
        case .badSystemID:
          throw sentence.fields.fieldError(type: .unknownValue, index: 8)
        default:
          fatalError("Did not expect \(error)")
      }
    }
  }
}
