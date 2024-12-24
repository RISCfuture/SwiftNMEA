import Collections
import Foundation

class XDRParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .transducerMeasurements
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let values: [Transducer.Value] = try stride(from: 0, to: sentence.fields.count, by: 4).map { i in
            let typeIndex = i,
                valueIndex = i + 1,
                unitsIndex = i + 2,
                idIndex = i + 3

            let type = try sentence.fields.enumeration(at: typeIndex, ofType: TransducerType.self)!,
                id = try sentence.fields.string(at: idIndex)!

            switch type {
                case .temperature:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: temperatureUnits)!
                    return .temperature(value, id: id)
                case .angle:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: angleUnits)!
                    return .angle(value, id: id)
                case .absoluteHumidity:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: densityUnits)!
                    return .absoluteHumidity(value, id: id)
                case .displacement:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: lengthUnits)!
                    return .displacement(value, id: id)
                case .frequency:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: frequencyUnits)!
                    return .frequency(value, id: id)
                case .salinity:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: dispersionUnits)!
                    return .salinity(value, id: id)
                case .force:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: forceUnits)!
                    return .force(value, id: id)
                case .pressure:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: pressureUnits)!
                    return .pressure(value, id: id)
                case .flowRate:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: flowUnits)!
                    return .flowRate(value, id: id)
                case .tachometer:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: angularVelocityUnits)!
                    return .tachometer(value, id: id)
                case .relativeHumidity:
                    let value = try sentence.fields.float(at: valueIndex)!
                    return .relativeHumidity(value, id: id)
                case .volume:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: volumeUnits)!
                    return .volume(value, id: id)
                case .electricPotential:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: potentialUnits)!
                    return .electricPotential(value, id: id)
                case .electricCurrent:
                    let value = try sentence.fields.measurement(at: valueIndex, valueType: .float, unitAt: unitsIndex, units: currentUnits)!
                    return .electricCurrent(value, id: id)
                case .boolean:
                    let value = try sentence.fields.bool(at: valueIndex, trueValue: "1", falseValue: "0")!
                    return .boolean(value, id: id)
                case .generic:
                    let value = try sentence.fields.float(at: valueIndex)!
                    return .generic(value, id: id)
            }
        }

        return .transducerMeasurements(values)
    }
}

enum TransducerType: Character {
    case temperature = "C"
    case angle = "A"
    case absoluteHumidity = "B"
    case displacement = "D"
    case frequency = "F"
    case salinity = "L"
    case force = "N"
    case pressure = "P"
    case flowRate = "R"
    case tachometer = "T"
    case relativeHumidity = "H"
    case volume = "V"
    case electricPotential = "U"
    case electricCurrent = "I"
    case boolean = "S"
    case generic = "G"
}
