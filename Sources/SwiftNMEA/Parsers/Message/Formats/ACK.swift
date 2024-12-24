import Foundation

class ACKParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .alarmAcknowledgement
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let identifier = try sentence.fields.int(at: 0)!
        return .alarmAcknowledgement(identifier: identifier)
    }
}
