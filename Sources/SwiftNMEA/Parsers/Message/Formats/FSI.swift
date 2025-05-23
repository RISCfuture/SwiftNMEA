import Foundation

class FSIParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .frequencySetInfo
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let transmit = try sentence.fields.enumeration(at: 0, ofType: Comm.Frequency.self, optional: true),
            receive = try sentence.fields.enumeration(at: 1, ofType: Comm.Frequency.self, optional: true),
            mode = try sentence.fields.enumeration(at: 2, ofType: Comm.OperationMode.self, optional: true),
            powerLevel = try sentence.fields.int(at: 3, optional: true),
            type = try sentence.fields.enumeration(at: 4, ofType: SentenceType.self)!

        return .frequencySetInfo(transmit: transmit,
                                 receive: receive,
                                 mode: mode,
                                 powerLevel: powerLevel,
                                 type: type)
    }
}
