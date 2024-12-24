import Collections
import Foundation
import NMEAUnits

class TRCParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .thrusterControl
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let number = try sentence.fields.int(at: 0)!,
            RPMMode = try sentence.fields.character(at: 2)!,
            pitchMode = try sentence.fields.character(at: 4)!,
            azimuthDemand = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitAngle.degrees, optional: true),
            location = try sentence.fields.enumeration(at: 6, ofType: Propulsion.Location.self)!,
            status = try sentence.fields.enumeration(at: 7, ofType: SentenceType.self)!

        let RPMDemand: Propulsion.RPMValue = switch RPMMode {
            case "P": .percent(try sentence.fields.float(at: 1)!)
            case "R": .value(try sentence.fields.measurement(at: 1, valueType: .float, units: .revolutionsPerMinute)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 1)
        }
        let pitchDemand: Propulsion.PitchValue = switch pitchMode {
            case "P": .percent(try sentence.fields.float(at: 3)!)
            case "D": .value(try sentence.fields.measurement(at: 3, valueType: .float, units: .degrees)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 3)
        }

        return .thrusterControl(number: number,
                                RPM: RPMDemand,
                                pitch: pitchDemand,
                                azimuth: azimuthDemand,
                                location: location,
                                status: status)
    }
}
