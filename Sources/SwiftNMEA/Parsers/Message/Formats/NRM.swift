import Foundation
import NMEAUnits

class NRMParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .NAVTEXReceiverMask
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let function = try sentence.fields.enumeration(at: 0, ofType: NAVTEX.FunctionCode.self)!,
            frequency = try sentence.fields.enumeration(at: 1, ofType: NAVTEX.Frequency.self)!,
            coverageMask = try sentence.fields.enumeration(at: 2, ofType: NAVTEX.Mask.self, optional: true),
            typeMask = try sentence.fields.enumeration(at: 3, ofType: NAVTEX.Mask.self, optional: true),
            status = try sentence.fields.enumeration(at: 4, ofType: SentenceType.self)!

        return .NAVTEXReceiverMask(function: function,
                                   frequency: frequency,
                                   coverageAreaMask: coverageMask,
                                   messageTypeMask: typeMask,
                                   status: status)
    }
}
