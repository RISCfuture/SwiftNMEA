import Foundation

class GNSParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GNSSFix
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            position = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4), altitudeIndex: (8, nil), optional: true, altitudeType: .float),
            modes = try sentence.fields.string(at: 5, optional: true),
            satellites = try sentence.fields.int(at: 6)!,
            HDOP = try sentence.fields.float(at: 7, optional: true),
            separation = try sentence.fields.measurement(at: 9, valueType: .float, units: UnitLength.meters, optional: true),
            dAge = try sentence.fields.measurement(at: 10, valueType: .float, units: UnitDuration.seconds, optional: true),
            dReferenceID = try sentence.fields.int(at: 11, optional: true),
            status = try sentence.fields.enumeration(at: 12, ofType: GNSS.IntegrityStatus.self)!

        let mode = try modes.map { modes in
            let GPSChar = modes.char(at: 0),
                GLONASSChar = modes.char(at: 1),
                galileoChar = modes.char(at: 2),
                GPSMode = try GPSChar.map { char in
                    guard let mode = Navigation.Mode(rawValue: char) else {
                        throw sentence.fields.fieldError(type: .unknownValue, index: 5)
                    }
                    return mode
                },
                GLONASSMode = try GLONASSChar.map { char in
                    guard let mode = Navigation.Mode(rawValue: char) else {
                        throw sentence.fields.fieldError(type: .unknownValue, index: 5)
                    }
                    return mode
                },
                galileoMode = try galileoChar.map { char in
                    guard let mode = Navigation.Mode(rawValue: char) else {
                        throw sentence.fields.fieldError(type: .unknownValue, index: 5)
                    }
                    return mode
                }
            return [
                GNSS.System.GPS: GPSMode,
                GNSS.System.GLONASS: GLONASSMode,
                GNSS.System.galileo: galileoMode
            ].compactMapValues(\.self)
        }

        return .GNSSFix(position,
                        time: time,
                        mode: mode,
                        numSatellites: satellites,
                        HDOP: HDOP,
                        geoidalSeparation: separation,
                        DGPSAge: dAge,
                        DGPSReferenceStationID: dReferenceID,
                        status: status)
    }
}
