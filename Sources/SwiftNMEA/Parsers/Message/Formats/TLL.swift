import Collections
import Foundation
import NMEAUnits

class TLLParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .targetPosition
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let number = try sentence.fields.int(at: 0)!
    let position = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4))!
    let name = try sentence.fields.string(at: 5)!
    let time = try sentence.fields.hmsDecimal(at: 6, searchDirection: .backward)!
    let status = try sentence.fields.enumeration(at: 7, ofType: Radar.TargetStatus.self)!
    let isReference = try sentence.fields.string(at: 8, optional: true) == "R"

    return .targetPosition(
      number: number,
      position: position,
      name: name,
      time: time,
      status: status,
      isReference: isReference
    )
  }
}
