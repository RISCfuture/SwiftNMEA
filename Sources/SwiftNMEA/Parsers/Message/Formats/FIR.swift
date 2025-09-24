import Foundation

class FIRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .fireDetection
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let type = try sentence.fields.enumeration(at: 0, ofType: Fire.MessageType.self)!
    let time = try sentence.fields.hmsDecimal(at: 1, searchDirection: .backward, optional: true)
    let detector = try sentence.fields.enumeration(at: 2, ofType: Fire.DetectorType.self)!
    let zone = try sentence.fields.string(at: 3, optional: true)
    let loop = try sentence.fields.int(at: 4, optional: true)
    let number = try sentence.fields.int(at: 5)!
    let condition = try sentence.fields.enumeration(
      at: 6,
      ofType: Fire.DetectorCondition.self,
      optional: true
    )
    let isAcknowledged = try sentence.fields.bool(at: 7, optional: true)
    let description = try sentence.fields.string(at: 8, optional: true)

    return .fireDetection(
      type: type,
      time: time,
      detector: detector,
      zone: zone,
      loop: loop,
      number: number,
      condition: condition,
      isAcknowledged: isAcknowledged,
      description: description
    )
  }
}
