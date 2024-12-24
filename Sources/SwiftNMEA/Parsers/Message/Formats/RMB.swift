import Foundation
import NMEAUnits

class RMBParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .destinationMinimumData
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let isValid = try sentence.fields.bool(at: 0)!,
            xte = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitLength.nauticalMiles)!,
            isLeft = try sentence.fields.bool(at: 2, trueValue: "L", falseValue: "R")!,
            originID = try sentence.fields.string(at: 3)!,
            destID = try sentence.fields.string(at: 4)!,
            destPosition = try sentence.fields.position(latitudeIndex: (5, 6), longitudeIndex: (7, 8))!,
            rangeDest = try sentence.fields.measurement(at: 9, valueType: .float, units: UnitLength.nauticalMiles)!,
            bearingDest = try sentence.fields.bearing(at: 10, valueType: .float, reference: .true)!,
            closingVelocity = try sentence.fields.measurement(at: 11, valueType: .float, units: UnitSpeed.knots)!,
            isArrived = try sentence.fields.bool(at: 12)!,
            mode = try sentence.fields.enumeration(at: 13, ofType: Navigation.Mode.self)!

        return .destinationMinimumData(isValid: isValid,
                                       crossTrackError: isLeft ? xte * -1 : xte,
                                       originID: originID,
                                       destinationID: destID,
                                       destination: destPosition,
                                       rangeToDestination: rangeDest,
                                       bearingToDestination: bearingDest,
                                       closingVelocity: closingVelocity,
                                       isArrived: isArrived,
                                       mode: mode)
    }
}
