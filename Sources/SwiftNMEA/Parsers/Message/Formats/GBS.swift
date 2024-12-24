import Foundation

class GBSParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GNSSFaultDetection
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            latitudeError = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitLength.meters)!,
            longitudeError = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitLength.meters)!,
            altitudeError = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!,
            satelliteNum = try sentence.fields.int(at: 4)!,
            missProbability = try sentence.fields.float(at: 5)!,
            biasEstimate = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitLength.meters)!,
            standardDeviation = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!,
            systemID = try sentence.fields.int(at: 8)!,
            signalID = try sentence.fields.int(at: 9)!

        do {
            let satelliteID = try GNSS.SatelliteID(systemID: systemID, svID: satelliteNum, signalID: signalID)

            return .GNSSFaultDetection(time: time,
                                       latitudeError: latitudeError,
                                       longitudeError: longitudeError,
                                       altitudeError: altitudeError,
                                       failedSatellite: satelliteID,
                                       missProbability: missProbability,
                                       biasEstimate: biasEstimate,
                                       biasEstimateStddev: standardDeviation)
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
