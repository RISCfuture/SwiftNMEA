import Foundation
import NMEAUnits

class VBWParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .speedData
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let waterSpeedLon = try sentence.fields.measurement(at: 0, valueType: .float, units: UnitSpeed.knots)!,
            waterSpeedTr = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitSpeed.knots)!,
            waterSpeedValid = try sentence.fields.bool(at: 2)!,
            groundSpeedLon = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitSpeed.knots)!,
            groundSpeedTr = try sentence.fields.measurement(at: 4, valueType: .float, units: UnitSpeed.knots)!,
            groundSpeedValid = try sentence.fields.bool(at: 5)!,
            sternWaterSpeed = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitSpeed.knots)!,
            sternWaterSpeedValid = try sentence.fields.bool(at: 7)!,
            sternGroundSpeed = try sentence.fields.measurement(at: 8, valueType: .float, units: UnitSpeed.knots)!,
            sternGroundSpeedValid = try sentence.fields.bool(at: 9)!

        let waterSpeed = SpeedVector(longitudinal: waterSpeedLon, transverse: waterSpeedTr),
            groundSpeed = SpeedVector(longitudinal: groundSpeedLon, transverse: groundSpeedTr)

        return .speedData(water: waterSpeed,
                          waterValid: waterSpeedValid,
                          ground: groundSpeed,
                          groundValid: groundSpeedValid,
                          sternTransverseWater: sternWaterSpeed,
                          sternTransverseWaterValid: sternWaterSpeedValid,
                          sternTransverseGround: sternGroundSpeed,
                          sternTransverseGroundValid: sternGroundSpeedValid)
    }
}
