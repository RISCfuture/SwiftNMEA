import Foundation
import NMEAUnits

class VDRParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .currentSetDrift
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let directionTrue = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!,
            directionMagnetic = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!,
            speed = try sentence.fields.measurement(at: 4, valueType: .float, unitAt: 5, units: speedUnits)!

        return .currentSetDrift(setTrue: directionTrue, setMagnetic: directionMagnetic, drift: speed)
    }
}
