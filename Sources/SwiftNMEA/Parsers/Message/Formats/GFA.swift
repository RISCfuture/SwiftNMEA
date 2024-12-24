import Foundation

class GFAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GNSSAccuracyIntegrity
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            HPL = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitLength.meters)!,
            VPL = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitLength.meters)!,
            semimajorStddev = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!,
            semiminorStddev = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitLength.meters)!,
            orientation = try sentence.fields.bearing(at: 5, valueType: .float, reference: .true)!,
            altitudeStddev = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitLength.meters)!,
            selectedAccuracy = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!,
            integrityStatusStr = try sentence.fields.string(at: 8)!

        guard let RAIMChar = integrityStatusStr.char(at: 0),
              let SBASChar = integrityStatusStr.char(at: 1),
              let GICChar = integrityStatusStr.char(at: 2),
              let RAIMStatus = GNSS.IntegrityStatus(rawValue: RAIMChar),
              let SBASStatus = GNSS.IntegrityStatus(rawValue: SBASChar),
              let GICStatus = GNSS.IntegrityStatus(rawValue: GICChar) else {
            throw sentence.fields.fieldError(type: .unknownValue, index: 8)
        }

        let integrityStatus: [GNSS.IntegritySource: GNSS.IntegrityStatus] = [
            .RAIM: RAIMStatus,
            .SBAS: SBASStatus,
            .GIC: GICStatus
        ]

        return .GNSSAccuracyIntegrity(time: time,
                                      HPL: HPL,
                                      VPL: VPL,
                                      semimajorStddev: semimajorStddev,
                                      semiminorStddev: semiminorStddev,
                                      semimajorErrorOrientation: orientation,
                                      altitudeStddev: altitudeStddev,
                                      selectedAccuracy: selectedAccuracy,
                                      integrity: integrityStatus)
    }
}
