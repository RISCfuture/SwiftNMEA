import Foundation
import NMEAUnits

class ROTParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .rateOfTurn
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let rate = try sentence.fields.measurement(at: 0, valueType: .float, units: UnitAngularVelocity.degreesPerMinute)!,
            isValid = try sentence.fields.bool(at: 1)!

        return .rateOfTurn(rate: rate, isValid: isValid)
    }
}
