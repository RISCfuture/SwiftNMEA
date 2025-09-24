import Foundation
import NMEAUnits

class POSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .positionDimensions
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let equipmentID = try sentence.fields.enumeration(at: 0, ofType: Talker.self)!
    let equipmentNum = try sentence.fields.int(at: 1)!
    let positionValid = try sentence.fields.bool(at: 2)!
    let posX = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!
    let posY = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitLength.meters)!
    let posZ = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitLength.meters)!
    let dimensionsValid = try sentence.fields.bool(at: 6)!
    let width = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!
    let length = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      units: UnitLength.meters
    )!
    let status = try sentence.fields.enumeration(at: 9, ofType: SentenceType.self)!

    let position = Coordinate(x: posX, y: posY, z: posZ)
    let dimensions = Dimensions(length: length, width: width)

    return .positionDimensions(
      equipment: equipmentID,
      equipmentNumber: equipmentNum,
      positionValid: positionValid,
      position: position,
      dimensionsValid: dimensionsValid,
      dimensions: dimensions,
      status: status
    )
  }
}
