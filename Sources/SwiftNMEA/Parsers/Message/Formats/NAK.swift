import Foundation
import NMEAUnits

class NAKParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .negativeAcknowledgement
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let talker = try sentence.fields.enumeration(at: 0, ofType: Talker.self)!,
            format = try sentence.fields.enumeration(at: 1, ofType: Format.self)!,
            uniqueID = try sentence.fields.string(at: 2, optional: true),
            reasonCode = try sentence.fields.enumeration(at: 3, ofType: NAKReason.self)!,
            reasonText = try sentence.fields.string(at: 4, optional: true)

        return .negativeAcknowledgement(talker: talker,
                                        format: format,
                                        uniqueID: uniqueID,
                                        reasonCode: reasonCode,
                                        reason: reasonText)
    }
}
