import Foundation

class GSAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .GNSS_DOP
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let lastValue = try sentence.fields.string(at: sentence.fields.endIndex - 1)!
        if lastValue.contains(".") { // last parameter is a DOP
            return try parseSTA8089FG(sentence: sentence)
        }
        return try parseSpec(sentence: sentence)
    }

    private func parseSpec(sentence: ParametricSentence) throws -> Message.Payload? {
        let autoMode = try sentence.fields.bool(at: 0, trueValue: "A", falseValue: "M")!,
            fixMode = try sentence.fields.enumeration(at: 1, ofType: GNSS.SolutionType.self)!,
            PDOP = try sentence.fields.float(at: sentence.fields.endIndex - 4)!,
            HDOP = try sentence.fields.float(at: sentence.fields.endIndex - 3)!,
            VDOP = try sentence.fields.float(at: sentence.fields.endIndex - 2)!,
            systemID = try sentence.fields.int(at: sentence.fields.endIndex - 1)!,
            ids = try (2..<(sentence.fields.endIndex - 4)).compactMap { index in
                do {
                    let svID = try sentence.fields.int(at: index, optional: true)
                    return try svID.map { try GNSS.SatelliteID(systemID: systemID, svID: $0) }
                } catch let error as GNSS.SatelliteID.Errors {
                    switch error {
                        case .badSignalID:
                            fatalError("No signalID")
                        case .badSystemID:
                            throw sentence.fields.fieldError(type: .unknownValue, index: sentence.fields.endIndex - 1)
                        default:
                            fatalError("Did not expect \(error)")
                    }
                }
            }

        return .GNSS_DOP(PDOP: PDOP,
                         HDOP: HDOP,
                         VDOP: VDOP,
                         auto3D: autoMode,
                         solution: fixMode,
                         ids: ids)
    }

    private func parseSTA8089FG(sentence: ParametricSentence) throws -> Message.Payload? {
        let autoMode = try sentence.fields.bool(at: 0, trueValue: "A", falseValue: "M")!,
            fixMode = try sentence.fields.enumeration(at: 1, ofType: GNSS.SolutionType.self)!,
            PDOP = try sentence.fields.float(at: sentence.fields.endIndex - 3)!,
            HDOP = try sentence.fields.float(at: sentence.fields.endIndex - 2)!,
            VDOP = try sentence.fields.float(at: sentence.fields.endIndex - 1)!,
            ids = try (2..<(sentence.fields.endIndex - 3)).compactMap { index in
                do {
                    let svID = try sentence.fields.int(at: index, optional: true)
                    return try svID.map { try GNSS.SatelliteID(svID: $0) }
                } catch let error as GNSS.SatelliteID.Errors {
                    switch error {
                        case .badSignalID:
                            fatalError("No signalID")
                        case .badSystemID:
                            throw sentence.fields.fieldError(type: .unknownValue, index: sentence.fields.endIndex - 1)
                        default:
                            fatalError("Did not expect \(error)")
                    }
                }
            }

        return .GNSS_DOP(PDOP: PDOP,
                         HDOP: HDOP,
                         VDOP: VDOP,
                         auto3D: autoMode,
                         solution: fixMode,
                         ids: ids)
    }
}
