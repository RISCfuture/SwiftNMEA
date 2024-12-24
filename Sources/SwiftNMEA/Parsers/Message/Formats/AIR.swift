import Foundation

class AIRParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .AISInterrogationRequest
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let MMSI1 = try sentence.fields.int(at: 0)!,
            messageID1_1 = try sentence.fields.string(at: 1)!,
            messageID1_2 = try sentence.fields.string(at: 2, optional: true),
            MMSI2 = try sentence.fields.int(at: 3, optional: true),
            messageID2 = try sentence.fields.string(at: 4, optional: true),
            channel = try sentence.fields.enumeration(at: 5, ofType: AIS.Channel.self, optional: true),
            replySlot1_1 = try sentence.fields.int(at: 6, optional: true),
            replySlot1_2 = try sentence.fields.int(at: 7, optional: true),
            replySlot2 = try sentence.fields.int(at: 8, optional: true)

        guard let message1_1 = AIS.MessageRequest(ID: messageID1_1, replySlot: replySlot1_1) else {
            throw sentence.fields.fieldError(type: .badValue, index: 1)
        }
        let message1_2 = try messageID1_2.map { ID1_2 in
            guard let message = AIS.MessageRequest(ID: ID1_2, replySlot: replySlot1_2) else {
                throw sentence.fields.fieldError(type: .badValue, index: 2)
            }
            return message
        }
        let message2 = try messageID2.map { ID2 in
            guard let message = AIS.MessageRequest(ID: ID2, replySlot: replySlot2) else {
                throw sentence.fields.fieldError(type: .badValue, index: 4)
            }
            return message
        }

        return .AISInterrogationRequest(station1: MMSI1,
                                        station1Request1: message1_1,
                                        station1Request2: message1_2,
                                        station2: MMSI2,
                                        station2Request: message2,
                                        channel: channel)
    }
}
