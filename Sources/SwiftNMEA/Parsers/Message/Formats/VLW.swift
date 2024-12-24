import Collections
import Foundation
import NMEAUnits

class VLWParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .distanceData
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let waterCum = try sentence.fields.measurement(at: 0, valueType: .float, unitAt: 1, units: lengthUnits)!,
            waterReset = try sentence.fields.measurement(at: 2, valueType: .float, unitAt: 3, units: lengthUnits)!,
            groundCum = try sentence.fields.measurement(at: 4, valueType: .float, unitAt: 5, units: lengthUnits)!,
            groundReset = try sentence.fields.measurement(at: 6, valueType: .float, unitAt: 7, units: lengthUnits)!

        return .distanceData(waterCumulative: waterCum,
                             waterSinceReset: waterReset,
                             groundCumulative: groundCum,
                             groundSinceReset: groundReset)
    }
}
