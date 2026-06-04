import Foundation

class GSVParser: MessageFormat {
  private var satellites = [Talker: SatelliteData]()

  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSSatellitesInView
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let totalMessages = try sentence.fields.int(at: 0)!
    let messageNumber = try sentence.fields.int(at: 1)!
    let totalSatellites = try sentence.fields.int(at: 2, optional: true)
    // Signal ID is a hex ('h') field reaching A–F; the System is identified by
    // the talker (GP/GL/GA/GB/GQ/GI), not the satellite ID range
    guard
      let signalID = Int(
        exactly: try sentence.fields.hex(at: sentence.fields.endIndex - 1, width: nil)!
      )
    else {
      throw sentence.fields.fieldError(type: .badNumericValue, index: sentence.fields.endIndex - 1)
    }
    let systemID = GNSS.systemID(forTalker: sentence.talker)
    let satelliteData = try (3..<(sentence.fields.endIndex - 1)).chunks(ofCount: 4).compactMap {
      chunk in
      guard let svID = try sentence.fields.int(at: chunk.startIndex, optional: true) else {
        return nil as GNSS.SatelliteInView?
      }
      let elevation = try sentence.fields.measurement(
        at: chunk.index(after: chunk.startIndex),
        valueType: .integer,
        units: UnitAngle.degrees
      )!
      let azimuth = try sentence.fields.bearing(
        at: chunk.index(chunk.startIndex, offsetBy: 2),
        valueType: .integer,
        reference: .true
      )!
      let SNR = try sentence.fields.int(
        at: chunk.index(chunk.startIndex, offsetBy: 3),
        optional: true
      )
      let id: GNSS.SatelliteID
      do {
        id =
          try systemID.map { try GNSS.SatelliteID(systemID: $0, svID: svID, signalID: signalID) }
          ?? GNSS.SatelliteID(svID: svID, signalID: signalID)
      } catch let error as GNSS.SatelliteID.Errors {
        switch error {
          case .badSignalID:
            throw sentence.fields.fieldError(
              type: .unknownValue,
              index: sentence.fields.endIndex - 1
            )
          case .badSvID:
            throw sentence.fields.fieldError(type: .unknownValue, index: chunk.startIndex)
          case .badSystemID:
            throw sentence.fields.lineError(type: .unknownTalker)
        }
      }
      return GNSS.SatelliteInView(
        id: id,
        position: .init(elevation: elevation, azimuth: azimuth),
        SNR: SNR
      )
    }

    if !satellites.keys.contains(sentence.talker) {
      guard let totalSatellites else {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
      }
      satellites[sentence.talker] = .init(
        totalSatellites: totalSatellites,
        totalMessages: totalMessages
      )
    }

    satellites[sentence.talker]!.satellites.append(contentsOf: satelliteData)
    if satellites[sentence.talker]!.totalMessages == messageNumber {
      return .GNSSSatellitesInView(
        satellites[sentence.talker]!.satellites,
        total: satellites[sentence.talker]!.totalSatellites
      )
    }
    return nil
  }

  struct SatelliteData {
    let totalSatellites: Int
    let totalMessages: Int
    var satellites = [GNSS.SatelliteInView]()
  }
}
