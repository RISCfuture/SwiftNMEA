import Foundation

class BODParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .bearingOriginToDest
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let trueBearing = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!,
            magneticBearing = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!,
            destID = try sentence.fields.string(at: 4)!,
            originID = try sentence.fields.string(at: 5)!

        return .bearingOriginToDest(bearingTrue: trueBearing,
                                    bearingMagnetic: magneticBearing,
                                    destinationWaypointID: destID,
                                    originWaypointID: originID)
    }
}
