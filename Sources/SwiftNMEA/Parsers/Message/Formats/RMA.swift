import Foundation
import NMEAUnits

class RMAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .LORANCMinimumData
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let isValid = try sentence.fields.bool(at: 0)!,
            position = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4), optional: true),
            timeDiffA = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitDuration.microseconds, optional: true),
            timeDiffB = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitDuration.microseconds, optional: true),
            speed = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitSpeed.knots, optional: true),
            course = try sentence.fields.bearing(at: 8, valueType: .float, reference: .true, optional: true),
            magVar = try sentence.fields.deviation(at: (9, 10), valueType: .float, optional: true),
            mode = try sentence.fields.enumeration(at: 11, ofType: Navigation.Mode.self)!

        return .LORANCMinimumData(isValid: isValid,
                                  position: position,
                                  timeDifferenceA: timeDiffA,
                                  timeDifferenceB: timeDiffB,
                                  speed: speed,
                                  course: course,
                                  magneticVariation: magVar,
                                  mode: mode)
    }
}
