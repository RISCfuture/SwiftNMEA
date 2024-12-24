import Foundation
import NMEAUnits

class POSParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .positionDimensions
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let equipmentID = try sentence.fields.enumeration(at: 0, ofType: Talker.self)!,
            equipmentNum = try sentence.fields.int(at: 1)!,
            positionValid = try sentence.fields.bool(at: 2)!,
            posX = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!,
            posY = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitLength.meters)!,
            posZ = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitLength.meters)!,
            dimensionsValid = try sentence.fields.bool(at: 6)!,
            width = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!,
            length = try sentence.fields.measurement(at: 8, valueType: .float, units: UnitLength.meters)!,
            status = try sentence.fields.enumeration(at: 9, ofType: SentenceType.self)!

        let position = Coordinate(x: posX, y: posY, z: posZ),
            dimensions = Dimensions(length: length, width: width)

        return .positionDimensions(equipment: equipmentID,
                                   equipmentNumber: equipmentNum,
                                   positionValid: positionValid,
                                   position: position,
                                   dimensionsValid: dimensionsValid,
                                   dimensions: dimensions,
                                   status: status)
    }
}
