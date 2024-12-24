import Foundation

class BDWaypointParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && (
            sentence.format == .bearingDistanceToWaypointDR ||
            sentence.format == .bearingDistanceToWaypointGC ||
            sentence.format == .bearingDistanceToWaypointRL)
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            position = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4))!,
            trueBearing = try sentence.fields.bearing(at: 5, valueType: .float, referenceIndex: 6)!,
            magneticBearing = try sentence.fields.bearing(at: 7, valueType: .float, referenceIndex: 8)!,
            distance = try sentence.fields.measurement(at: 9, valueType: .float, unitAt: 10, units: lengthUnits)!,
            waypointID = try sentence.fields.string(at: 11)!

        switch sentence.format {
            case Format.bearingDistanceToWaypointDR:
                return .bearingDistanceToWaypointDR(observationTime: time,
                                                    waypointPosition: position,
                                                    bearingTrue: trueBearing,
                                                    bearingMagnetic: magneticBearing,
                                                    distance: distance,
                                                    waypointID: waypointID)
            case Format.bearingDistanceToWaypointGC:
                let mode = try sentence.fields.enumeration(at: 12, ofType: Navigation.Mode.self)!
                return .bearingDistanceToWaypointGC(observationTime: time,
                                                    position: position,
                                                    bearingTrue: trueBearing,
                                                    bearingMagnetic: magneticBearing,
                                                    distance: distance,
                                                    waypointID: waypointID,
                                                    mode: mode)
            case Format.bearingDistanceToWaypointRL:
                let mode = try sentence.fields.enumeration(at: 12, ofType: Navigation.Mode.self)!
                return .bearingDistanceToWaypointRL(observationTime: time,
                                                    position: position,
                                                    bearingTrue: trueBearing,
                                                    bearingMagnetic: magneticBearing,
                                                    distance: distance,
                                                    waypointID: waypointID,
                                                    mode: mode)
            default:
                fatalError("Unexpected messageType \(sentence.format)")
        }
    }
}
