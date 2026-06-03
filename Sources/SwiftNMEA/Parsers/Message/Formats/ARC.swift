import Foundation

class ARCParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .alertCommandRefused
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

    let alert = Alert.Identifier(
      manufacturerMnemonic: manufacturerMnemonic,
      identifier: UInt(identifierValue),
      instance: instance
    )

    let refusedCommand = try sentence.fields.enumeration(at: 4, ofType: Alert.Command.self)!

    return .alertCommandRefused(time: time, alert: alert, refusedCommand: refusedCommand)
  }
}
