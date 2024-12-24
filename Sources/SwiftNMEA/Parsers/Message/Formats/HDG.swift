import Foundation

class HDGParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .heading
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let heading = try sentence.fields.bearing(at: 0, valueType: .float, reference: .magnetic)!,
            deviation = try sentence.fields.deviation(at: (1, 2), valueType: .float, optional: true),
            variation = try sentence.fields.deviation(at: (3, 4), valueType: .float, optional: true)

        return .heading(heading, deviation: deviation, variation: variation)
    }
}
