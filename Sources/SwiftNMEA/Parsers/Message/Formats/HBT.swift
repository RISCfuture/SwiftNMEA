import Foundation

class HBTParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .heartbeat
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let interval = try sentence.fields.measurement(at: 0, valueType: .float, units: UnitDuration.seconds, optional: true),
            isNormal = try sentence.fields.bool(at: 1)!,
            sequenceNumber = try sentence.fields.int(at: 2)!

        return .heartbeat(interval: interval, isNormal: isNormal, sequenceNumber: sequenceNumber)
    }
}
