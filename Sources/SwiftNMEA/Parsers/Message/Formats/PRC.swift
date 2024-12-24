import Foundation
import NMEAUnits

class PRCParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .propulsionRemoteControl
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let leverPosition = try sentence.fields.float(at: 0)!,
            leverStatus = try sentence.fields.bool(at: 1)!,
            RPMMode = try sentence.fields.character(at: 3)!,
            pitchMode = try sentence.fields.character(at: 5)!,
            location = try sentence.fields.enumeration(at: 6, ofType: Propulsion.Location.self, optional: true),
            number = try sentence.fields.int(at: 7)!

        let RPMDemand: Propulsion.RPMValue = switch RPMMode {
            case "P": .percent(try sentence.fields.float(at: 2)!)
            case "R": .value(try sentence.fields.measurement(at: 2, valueType: .float, units: .revolutionsPerMinute)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 2)
        }
        let pitchDemand: Propulsion.PitchValue = switch pitchMode {
            case "P": .percent(try sentence.fields.float(at: 4)!)
            case "D": .value(try sentence.fields.measurement(at: 4, valueType: .float, units: .degrees)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 4)
        }

        return .propulsionRemoteControl(leverDemandPosition: leverPosition,
                                        leverDemandValid: leverStatus,
                                        RPMDemand: RPMDemand,
                                        pitchDemand: pitchDemand,
                                        location: location,
                                        engineNumber: number)
    }
}
