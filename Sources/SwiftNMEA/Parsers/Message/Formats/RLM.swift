import Foundation

class RLMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .returnLink
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    // Beacon ID: fixed-length 15 hexadecimal character field, not null. Kept as
    // a string to preserve leading zeros and the exact 15-digit representation.
    let beaconID = try sentence.fields.string(at: 0)!
    guard beaconID.count == 15,
      beaconID.allSatisfy(\.isHexDigit)
    else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 0)
    }

    // Time of reception (UTC); may be null. Decimal seconds are ignored.
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)

    let messageCode = try sentence.fields.enumeration(at: 2, ofType: ReturnLink.MessageCode.self)!

    // Message body: variable-length hexadecimal field, not null.
    let messageBodyHex = try sentence.fields.string(at: 3)!
    guard let messageBody = Data(hex: messageBodyHex) else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 3)
    }

    return .returnLink(
      beacon: beaconID,
      time: time,
      messageCode: messageCode,
      messageBody: messageBody
    )
  }
}
