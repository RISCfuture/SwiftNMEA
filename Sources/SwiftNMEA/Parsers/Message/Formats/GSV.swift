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
    let signalID = try sentence.fields.int(at: sentence.fields.endIndex - 1)!
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
      let SNR = try sentence.fields.int(at: chunk.index(chunk.startIndex, offsetBy: 3))!
      let id = try GNSS.SatelliteID(svID: svID, signalID: signalID)
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
