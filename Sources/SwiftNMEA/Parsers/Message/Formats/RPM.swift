import Foundation
import NMEAUnits

class RPMParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .revolutions
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let source = try sentence.fields.enumeration(at: 0, ofType: Propulsion.ThrustSource.self)!,
            number = try sentence.fields.int(at: 1)!,
            speed = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitAngularVelocity.revolutionsPerMinute)!,
            pitch = try sentence.fields.float(at: 3)!,
            isValid = try sentence.fields.bool(at: 4)!

        return .revolutions(source: source,
                            number: number,
                            speed: speed,
                            pitch: pitch,
                            isValid: isValid)
    }
}
