import Collections
import Foundation
import NMEAUnits

class ZTGParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .timeToDestination
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let observation = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!,
            time = try sentence.fields.hmsDecimalDuration(at: 1)!,
            id = try sentence.fields.string(at: 2)!

        return .timeToDestination(observation: observation, timeToGo: time, destinationID: id)
    }
}
