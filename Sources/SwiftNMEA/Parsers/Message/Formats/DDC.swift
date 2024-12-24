import Foundation

class DDCParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .displayDimmingControl
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let preset = try sentence.fields.enumeration(at: 0, ofType: DimmingPreset.self, optional: true),
            brightness = try sentence.fields.int(at: 1, optional: true),
            palette = try sentence.fields.enumeration(at: 2, ofType: DimmingPreset.self, optional: true),
            status = try sentence.fields.enumeration(at: 3, ofType: SentenceType.self)!

        return .displayDimmingControl(preset: preset,
                                      brightness: brightness,
                                      colorPalette: palette,
                                      status: status)
    }
}
