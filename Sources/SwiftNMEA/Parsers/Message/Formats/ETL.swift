import Foundation

class ETLParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .engineTelegraph
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true),
            type = try sentence.fields.enumeration(at: 1, ofType: EngineTelegraph.MessageType.self)!,
            position = try sentence.fields.enumeration(at: 2, ofType: EngineTelegraph.Position.self)!,
            subPosition = try sentence.fields.enumeration(at: 3, ofType: EngineTelegraph.SubPosition.self)!,
            location = try sentence.fields.enumeration(at: 4, ofType: Propulsion.Location.self, optional: true),
            number = try sentence.fields.int(at: 5)!

        return .engineTelegraph(time: time,
                                type: type,
                                position: position,
                                subPosition: subPosition,
                                location: location,
                                number: number)
    }
}
