import Foundation

class SPWParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .securityPassword
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let protectedSentence = try sentence.fields.enumeration(at: 0, ofType: Format.self)!
    let uniqueID = try sentence.fields.string(at: 1)!
    let level = try sentence.fields.enumeration(at: 2, ofType: SecurityPassword.Level.self)!
    let password = try sentence.fields.string(at: 3)!

    return .securityPassword(
      protectedSentence: protectedSentence,
      uniqueID: uniqueID,
      level: level,
      password: password
    )
  }
}
