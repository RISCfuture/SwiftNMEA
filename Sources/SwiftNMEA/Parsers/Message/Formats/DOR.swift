import Foundation

class DORParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .doorStatus
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let messageType = try sentence.fields.enumeration(at: 0, ofType: Doors.MessageType.self)!,
            time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true),
            systemType = try sentence.fields.enumeration(at: 2, ofType: Doors.SystemType.self)!,
            division1 = try sentence.fields.string(at: 3, optional: true),
            division2 = try sentence.fields.string(at: 4, optional: true),
            doorNumber = try sentence.fields.int(at: 5, optional: true),
            status = try sentence.fields.enumeration(at: 6, ofType: Doors.Status.self, optional: true),
            switchSetting = try sentence.fields.enumeration(at: 7, ofType: Doors.SwitchSetting.self, optional: true),
            description = try sentence.fields.string(at: 8, optional: true)

        return .doorStatus(messageType: messageType,
                           time: time,
                           systemType: systemType,
                           division1: division1,
                           division2: division2,
                           doorNumber: doorNumber,
                           doorStatus: status,
                           switchSetting: switchSetting,
                           description: description)
    }
}
