import Foundation

class HSCParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .headingSteeringCommand
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let headingTrue = try sentence.fields.bearing(at: 0, valueType: .float, referenceIndex: 1)!,
            headingMag = try sentence.fields.bearing(at: 2, valueType: .float, referenceIndex: 3)!,
            status = try sentence.fields.enumeration(at: 4, ofType: SentenceType.self)!

        return .headingSteeringCommand(headingTrue: headingTrue, headingMagnetic: headingMag, status: status)
    }
}
