import Foundation

class GSTParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GNSSPseudorangeNoise
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            RMS = try sentence.fields.float(at: 1)!,
            semimajorStddev = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitLength.meters)!,
            semiminorStddev = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!,
            orientation = try sentence.fields.bearing(at: 4, valueType: .float, reference: .true)!,
            latStddev = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitLength.meters)!,
            lonStddev = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitLength.meters)!,
            altStddev = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!

        return .GNSSPseudorangeNoise(time: time,
                                     rangeStddevRMS: RMS,
                                     errorSemimajorStddev: semimajorStddev,
                                     errorSemiminorStddev: semiminorStddev,
                                     errorOrientation: orientation,
                                     errorLatitudeStddev: latStddev,
                                     errorLongitudeStddev: lonStddev,
                                     errorAltitudeStddev: altStddev)
    }
}
