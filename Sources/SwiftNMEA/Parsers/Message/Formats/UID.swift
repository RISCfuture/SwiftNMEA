import Foundation
import NMEAUnits

class UIDParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .userIdentification
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let code1 = try sentence.fields.string(at: 0)!,
            code2 = try sentence.fields.string(at: 1, optional: true)

        return .userIdentification(code1: code1, code2: code2)
    }
}
