import Foundation

class DTMParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .datumReference
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let localDatumStr = try sentence.fields.string(at: 0)!,
            localSubdivision = try sentence.fields.character(at: 1, optional: true),
            latOffsetMag = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitAngle.arcMinutes, optional: true),
            latOffsetHemisphere = try sentence.fields.character(at: 3, optional: true),
            lonOffsetMag = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitAngle.arcMinutes, optional: true),
            lonOffsetHemisphere = try sentence.fields.character(at: 5, optional: true),
            altOffset = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitLength.meters, optional: true),
            referenceDatumStr = try sentence.fields.string(at: 7)!

        guard let localDatum = Datum(rawValue: localDatumStr, subdivision: localSubdivision) else {
            throw sentence.fields.fieldError(type: .unknownValue, index: 0)
        }
        guard let referenceDatum = Datum(rawValue: referenceDatumStr) else {
            throw sentence.fields.fieldError(type: .unknownValue, index: 7)
        }

        let latOffset = try latOffsetMag.map { latOffsetMag in
            switch latOffsetHemisphere {
                case "N": latOffsetMag
                case "S": latOffsetMag * -1
                default: throw sentence.fields.fieldError(type: .badCharacterValue, index: 2)
            }
        }

        let lonOffset = try lonOffsetMag.map { lonOffsetMag in
            switch lonOffsetHemisphere {
                case "E": lonOffsetMag
                case "W": lonOffsetMag * -1
                default: throw sentence.fields.fieldError(type: .badCharacterValue, index: 5)
            }
        }

        return .datumReference(localDatum: localDatum,
                               latitudeOffset: latOffset,
                               longitudeOffset: lonOffset,
                               altitudeOffset: altOffset,
                               referenceDatum: referenceDatum)
    }
}
