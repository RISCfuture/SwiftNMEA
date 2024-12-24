import Foundation

class GGAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GPSFix
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            position = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4), altitudeIndex: (8, 9), altitudeType: .float)!,
            quality = try sentence.fields.enumeration(at: 5, ofType: GNSS.GPSQuality.self)!,
            numSatellites = try sentence.fields.int(at: 6)!,
            HDOP = try sentence.fields.float(at: 7)!,
            separation = try sentence.fields.measurement(at: 10, valueType: .float, unitAt: 11, units: lengthUnits)!,
            dGPSAge = try sentence.fields.measurement(at: 12, valueType: .float, units: UnitDuration.seconds, optional: true),
            dGPSStationID = try sentence.fields.int(at: 13, optional: true)

        return .GPSFix(position,
                       time: time,
                       quality: quality,
                       numSatellites: numSatellites,
                       HDOP: HDOP,
                       geoidalSeparation: separation,
                       DGPSAge: dGPSAge,
                       DGPSReferenceStationID: dGPSStationID)
    }
}
