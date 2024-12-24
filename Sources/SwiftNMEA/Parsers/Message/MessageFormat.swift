import Foundation

protocol MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool
    func parse(sentence: ParametricSentence) throws -> Message.Payload?
    func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element]
}

extension MessageFormat {
    func flush(talker _: Talker?, format _: Format?, includeIncomplete _: Bool) throws -> [any Element] { [] }
}
