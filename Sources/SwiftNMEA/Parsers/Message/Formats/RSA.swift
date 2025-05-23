import Foundation
import NMEAUnits

class RSAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .rudderSensorAngle
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let starboard = try sentence.fields.float(at: 0)!,
            starboardValid = try sentence.fields.bool(at: 1)!,
            port = try sentence.fields.float(at: 2, optional: true),
            portValid = try sentence.fields.bool(at: 3, optional: true)

        return .rudderSensorAngle(starboard: starboard,
                                  port: port,
                                  starboardValid: starboardValid,
                                  portValid: portValid)
    }
}
