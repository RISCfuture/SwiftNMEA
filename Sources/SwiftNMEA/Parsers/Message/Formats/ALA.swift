import Foundation

class ALAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .detailAlarm
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true),
            system = try sentence.fields.string(at: 1)!,
            subsystem = try sentence.fields.string(at: 2, optional: true),
            instance = try sentence.fields.int(at: 3)!,
            type = try sentence.fields.int(at: 4)!,
            condition = try sentence.fields.enumeration(at: 5, ofType: AlarmCondition.self)!,
            state = try sentence.fields.enumeration(at: 6, ofType: AlarmAcknowledgementState.self)!,
            description = try sentence.fields.string(at: 7, optional: true)

        guard let alarm = Alarm(system: system, subsystem: subsystem, type: type) else {
            throw sentence.fields.lineError(type: .badValue)
        }

        return .detailAlarm(time: time,
                            alarm: alarm,
                            instance: instance,
                            condition: condition,
                            acknowledgementState: state,
                            description: description)
    }
}
