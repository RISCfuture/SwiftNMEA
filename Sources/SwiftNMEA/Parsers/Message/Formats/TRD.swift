import Collections
import Foundation
import NMEAUnits

class TRDParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .thrusterResponse
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let number = try sentence.fields.int(at: 0)!,
            RPMMode = try sentence.fields.character(at: 2)!,
            pitchMode = try sentence.fields.character(at: 4)!,
            azimuthResponse = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitAngle.degrees, optional: true)

        let RPMResponse: Propulsion.RPMValue = switch RPMMode {
            case "P": .percent(try sentence.fields.float(at: 1)!)
            case "R": .value(try sentence.fields.measurement(at: 1, valueType: .float, units: .revolutionsPerMinute)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 1)
        }
        let pitchResponse: Propulsion.PitchValue = switch pitchMode {
            case "P": .percent(try sentence.fields.float(at: 3)!)
            case "D": .value(try sentence.fields.measurement(at: 3, valueType: .float, units: .degrees)!)
            case "V": .invalid
            default: throw sentence.fields.fieldError(type: .unknownValue, index: 3)
        }

        return .thrusterResponse(number: number,
                                 RPM: RPMResponse,
                                 pitch: pitchResponse,
                                 azimuth: azimuthResponse)
    }
}
