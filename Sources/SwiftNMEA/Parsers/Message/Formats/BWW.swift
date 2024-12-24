import Foundation

class BWWParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .bearingWaypointToWaypoint
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let trueBearing = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!,
            magneticBearing = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!,
            toID = try sentence.fields.string(at: 4)!,
            fromID = try sentence.fields.string(at: 5)!

        return .bearingWaypointToWaypoint(bearingTrue: trueBearing,
                                          bearingMagnetic: magneticBearing,
                                          toWaypointID: toID,
                                          fromWaypointID: fromID)
    }
}
