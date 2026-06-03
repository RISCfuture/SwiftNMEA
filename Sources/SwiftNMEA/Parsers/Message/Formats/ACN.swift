import Foundation

class ACNParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alertCommand
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward, optional: true)

    let manufacturerMnemonic = try sentence.fields.string(at: 1, optional: true)

    let identifierValue = try sentence.fields.int(at: 2)!
    guard identifierValue >= 0 else {
      throw sentence.fields.fieldError(type: .badValue, index: 2)
    }
    let instanceValue = try sentence.fields.int(at: 3, optional: true)
    var instance: UInt?
    if let instanceValue {
      guard instanceValue >= 0 else {
        throw sentence.fields.fieldError(type: .badValue, index: 3)
      }
      instance = UInt(instanceValue)
    }
    let identifier = Alert.Identifier(
      manufacturerMnemonic: manufacturerMnemonic,
      identifier: UInt(identifierValue),
      instance: instance
    )

    // Sentence status flag (comment 6): this field shall be "C", indicating a
    // command. A sentence without "C" is not a command.
    let sentenceType = try sentence.fields.enumeration(at: 4, ofType: SentenceType.self)!
    guard sentenceType == .command else {
      throw sentence.fields.fieldError(type: .badValue, index: 4)
    }

    let command = try sentence.fields.enumeration(at: 5, ofType: Alert.Command.self)!

    // Comment 5: acknowledge (A) and responsibility transfer (O) are not
    // allowed for alert instance 0 (the "all instances" wildcard).
    if instance == 0, command == .acknowledge || command == .responsibilityTransfer {
      throw sentence.fields.fieldError(type: .badValue, index: 5)
    }

    return .alertCommand(time: time, alert: identifier, command: command)
  }
}
