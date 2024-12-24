import Foundation

class APBParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .autopilotSentenceB
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let blinkFlag = try sentence.fields.bool(at: 0, trueValue: "V", falseValue: "A")!,
            cycleLockFlag = try sentence.fields.bool(at: 1, trueValue: "V", falseValue: "A")!,
            xte = try sentence.fields.measurement(at: 2, valueType: .float, unitAt: 4, units: lengthUnits)!,
            isLeft = try sentence.fields.bool(at: 3, trueValue: "L", falseValue: "R")!,
            arrivalCircleEntered = try sentence.fields.bool(at: 5)!,
            perpendicularPassed = try sentence.fields.bool(at: 6)!,
            bearingOriginToDest = try sentence.fields.bearing(at: 7, valueType: .float, referenceIndex: 8)!,
            destinationID = try sentence.fields.string(at: 9)!,
            bearingPPosToDest = try sentence.fields.bearing(at: 10, valueType: .float, referenceIndex: 11)!,
            headingToSteer = try sentence.fields.bearing(at: 12, valueType: .float, referenceIndex: 13)!,
            mode = try sentence.fields.enumeration(at: 14, ofType: Navigation.Mode.self)!

        return .autopilotSentenceB(LORANC_blinkSNRFlag: blinkFlag,
                                   LORANC_cycleLockWarningFlag: cycleLockFlag,
                                   crossTrackError: isLeft ? xte * -1 : xte,
                                   arrivalCircleEntered: arrivalCircleEntered,
                                   perpendicularPassed: perpendicularPassed,
                                   bearingOriginToDest: bearingOriginToDest,
                                   destinationID: destinationID,
                                   bearingPresentPosToDest: bearingPPosToDest,
                                   headingToDest: headingToSteer,
                                   mode: mode)
    }
}
