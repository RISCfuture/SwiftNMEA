import Foundation
import NMEAUnits

class MSSParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .MSKReceiverSignalStatus
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let signalStrength = try sentence.fields.float(at: 0)!,
            SNR = try sentence.fields.float(at: 1)!,
            frequency = try sentence.fields.measurement(at: 2, valueType: .float, units: UnitFrequency.kilohertz)!,
            bitRate = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitInformationTransferRate.bitsPerSecond)!,
            channel = try sentence.fields.int(at: 4, optional: true)

        return .MSKReceiverSignalStatus(signalStrength: signalStrength,
                                        SNR: SNR,
                                        frequency: frequency,
                                        bitRate: bitRate,
                                        channel: channel)
    }
}
