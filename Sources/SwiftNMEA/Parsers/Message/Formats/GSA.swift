import Foundation

class GSAParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSS_DOP
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let lastValue = try sentence.fields.string(at: sentence.fields.endIndex - 1)!
    if lastValue.contains(".") {  // last parameter is a DOP
      return try parseSTA8089FG(sentence: sentence)
    }
    return try parseSpec(sentence: sentence)
  }

  private func parseSpec(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let autoMode = try sentence.fields.bool(at: 0, trueValue: "A", falseValue: "M")!
    let fixMode = try sentence.fields.enumeration(at: 1, ofType: GNSS.SolutionType.self)!
    let PDOP = try sentence.fields.float(at: sentence.fields.endIndex - 4)!
    let HDOP = try sentence.fields.float(at: sentence.fields.endIndex - 3)!
    let VDOP = try sentence.fields.float(at: sentence.fields.endIndex - 2)!
    let systemID = try sentence.fields.int(at: sentence.fields.endIndex - 1)!
    var ids = [GNSS.SatelliteID]()
    for index in 2..<(sentence.fields.endIndex - 4) {
      guard let svID = try sentence.fields.int(at: index, optional: true) else { continue }
      do {
        ids.append(try GNSS.SatelliteID(systemID: systemID, svID: svID))
      } catch {
        switch error {
          case .badSignalID:
            fatalError("No signalID")
          case .badSystemID:
            throw sentence.fields.fieldError(
              type: .unknownValue,
              index: sentence.fields.endIndex - 1
            )
          case .badSvID(let id):
            fatalError("Did not expect badSvID(\(id))")
        }
      }
    }

    return .GNSS_DOP(
      PDOP: PDOP,
      HDOP: HDOP,
      VDOP: VDOP,
      auto3D: autoMode,
      solution: fixMode,
      ids: ids
    )
  }

  private func parseSTA8089FG(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let autoMode = try sentence.fields.bool(at: 0, trueValue: "A", falseValue: "M")!
    let fixMode = try sentence.fields.enumeration(at: 1, ofType: GNSS.SolutionType.self)!
    let PDOP = try sentence.fields.float(at: sentence.fields.endIndex - 3)!
    let HDOP = try sentence.fields.float(at: sentence.fields.endIndex - 2)!
    let VDOP = try sentence.fields.float(at: sentence.fields.endIndex - 1)!
    var ids = [GNSS.SatelliteID]()
    for index in 2..<(sentence.fields.endIndex - 3) {
      guard let svID = try sentence.fields.int(at: index, optional: true) else { continue }
      do {
        ids.append(try GNSS.SatelliteID(svID: svID))
      } catch {
        switch error {
          case .badSignalID:
            fatalError("No signalID")
          case .badSystemID:
            throw sentence.fields.fieldError(
              type: .unknownValue,
              index: sentence.fields.endIndex - 1
            )
          case .badSvID(let id):
            fatalError("Did not expect badSvID(\(id))")
        }
      }
    }

    return .GNSS_DOP(
      PDOP: PDOP,
      HDOP: HDOP,
      VDOP: VDOP,
      auto3D: autoMode,
      solution: fixMode,
      ids: ids
    )
  }
}
