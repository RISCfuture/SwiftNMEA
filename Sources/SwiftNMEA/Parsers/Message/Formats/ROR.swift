import Foundation
import NMEAUnits

class RORParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .rudderOrder
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let starboard = try sentence.fields.float(at: 0)!,
            starboardValid = try sentence.fields.bool(at: 1)!,
            port = try sentence.fields.float(at: 2, optional: true),
            portValid = try sentence.fields.bool(at: 3, optional: true),
            source = try sentence.fields.enumeration(at: 4, ofType: Propulsion.Location.self)!

        return .rudderOrder(starboard: starboard,
                            port: port,
                            starboardValid: starboardValid,
                            portValid: portValid,
                            commandSource: source)
    }
}
