import Foundation

protocol MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool
  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload?
  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws(NMEAError)
    -> [any Element]
}

extension MessageFormat {
  func flush(talker _: Talker?, format _: Format?, includeIncomplete _: Bool) throws(NMEAError)
    -> [any Element]
  { [] }
}
