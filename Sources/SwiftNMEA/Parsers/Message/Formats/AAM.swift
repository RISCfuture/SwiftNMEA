import Foundation

class AAMParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .waypointArrivalAlarm
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let arrivalCircleEntered = try sentence.fields.bool(at: 0)!,
            perpendicularPassed = try sentence.fields.bool(at: 1)!,
            radius = try sentence.fields.measurement(at: 2, valueType: .float, unitAt: 3, units: lengthUnits)!,
            waypointID = try sentence.fields.string(at: 4)!

        return .waypointArrivalAlarm(arrivalCircleEntered: arrivalCircleEntered,
                                     perpendicularPassed: perpendicularPassed,
                                     arrivalCircleRadius: radius,
                                     waypoint: waypointID)
    }
}
