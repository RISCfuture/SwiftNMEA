import Foundation

class EPVParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .equipmentProperty
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let status = try sentence.fields.enumeration(at: 0, ofType: SentenceType.self)!
    let type = try sentence.fields.enumeration(at: 1, ofType: Talker.self)!
    let uniqueID = try sentence.fields.string(at: 2)!
    let reference = EquipmentProperty.Reference(type: type, uniqueID: uniqueID)

    guard let raw = try sentence.fields.int(at: 3), raw >= 0 else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: 3)
    }
    let property = EquipmentProperty.Identifier(rawValue: UInt(raw))

    let value = try sentence.fields.string(at: 4)!

    return .equipmentProperty(
      type: status,
      reference: reference,
      property: property,
      value: value
    )
  }
}
