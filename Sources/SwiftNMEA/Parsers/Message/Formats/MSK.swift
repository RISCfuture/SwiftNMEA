import Foundation
import NMEAUnits

class MSKParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .MSKReceiverInterface
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let frequencyAuto = try sentence.fields.bool(at: 1, trueValue: "A", falseValue: "M")!,
            bitRateAuto = try sentence.fields.bool(at: 3, trueValue: "A", falseValue: "M")!,
            interval = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitDuration.seconds, optional: true),
            channel = try sentence.fields.int(at: 5, optional: true),
            status = try sentence.fields.enumeration(at: 6, ofType: SentenceType.self)!

        let frequency = try MSK.AutoMeasurement(isAuto: frequencyAuto) { try sentence.fields.measurement(at: 0, valueType: .float, units: UnitFrequency.kilohertz)! },
            bitRate = try MSK.AutoMeasurement(isAuto: bitRateAuto) { try sentence.fields.measurement(at: 2, valueType: .float, units: UnitInformationTransferRate.bitsPerSecond)! }

        return .MSKReceiverInterface(frequency: frequency,
                                     bitRate: bitRate,
                                     statusInterval: interval,
                                     channel: channel,
                                     status: status)
    }
}
