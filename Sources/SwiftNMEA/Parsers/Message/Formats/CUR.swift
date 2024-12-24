import Foundation

class CURParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .currentWaterLayer
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let validity = try sentence.fields.bool(at: 0)!,
            set = try sentence.fields.int(at: 1)!,
            layer = try sentence.fields.int(at: 2)!,
            depth = try sentence.fields.measurement(at: 3, valueType: .float, units: UnitLength.meters)!,
            direction = try sentence.fields.bearing(at: 4, valueType: .float, referenceIndex: 5)!,
            speed = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitSpeed.knots)!,
            referenceDepth = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.meters)!,
            heading = try sentence.fields.bearing(at: 8, valueType: .float, referenceIndex: 9)!,
            speedReference = try sentence.fields.enumeration(at: 10, ofType: WaterSensor.SpeedReference.self)!

        return .currentWaterLayer(isValid: validity,
                                  setNumber: set,
                                  layer: layer,
                                  depth: depth,
                                  direction: direction,
                                  speed: speed,
                                  referenceDepth: referenceDepth,
                                  heading: heading,
                                  speedReference: speedReference)
    }
}
