import Collections
import Foundation
import NMEAUnits

class WPLParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .waypointLocation
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let position = try sentence.fields.position(latitudeIndex: (0, 1), longitudeIndex: (2, 3))!,
            identifier = try sentence.fields.string(at: 4)!

        return .waypointLocation(position, identifier: identifier)
    }
}
