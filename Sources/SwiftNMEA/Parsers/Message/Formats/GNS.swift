import Foundation

class GNSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSFix
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let time = try sentence.fields.hmsDecimal(at: 0, searchDirection: .backward)!
    let position = try sentence.fields.position(
      latitudeIndex: (1, 2),
      longitudeIndex: (3, 4),
      altitudeIndex: (8, nil),
      optional: true,
      altitudeType: .float
    )
    let modes = try sentence.fields.string(at: 5, optional: true)
    let satellites = try sentence.fields.int(at: 6)!
    let HDOP = try sentence.fields.float(at: 7, optional: true)
    let separation = try sentence.fields.measurement(
      at: 9,
      valueType: .float,
      units: UnitLength.meters,
      optional: true
    )
    let dAge = try sentence.fields.measurement(
      at: 10,
      valueType: .float,
      units: UnitDuration.seconds,
      optional: true
    )
    let dReferenceID = try sentence.fields.int(at: 11, optional: true)
    let status = try sentence.fields.enumeration(at: 12, ofType: GNSS.IntegrityStatus.self)!

    let mode = try modes.map { modes -> [GNSS.System: Navigation.Mode] in
      // ed.6.0 defines six mode-indicator characters: GPS, GLONASS, Galileo,
      // BDS, QZSS, NavIC. Shorter strings report only the leading systems.
      func parseMode(at index: Int) throws -> Navigation.Mode? {
        try modes.char(at: index).map { char in
          guard let mode = Navigation.Mode(rawValue: char) else {
            throw sentence.fields.fieldError(type: .unknownValue, index: 5)
          }
          return mode
        }
      }
      return [
        GNSS.System.GPS: try parseMode(at: 0),
        GNSS.System.GLONASS: try parseMode(at: 1),
        GNSS.System.galileo: try parseMode(at: 2),
        GNSS.System.beidou: try parseMode(at: 3),
        GNSS.System.QZSS: try parseMode(at: 4),
        GNSS.System.navIC: try parseMode(at: 5)
      ].compactMapValues(\.self)
    }

    return .GNSSFix(
      position,
      time: time,
      mode: mode,
      numSatellites: satellites,
      HDOP: HDOP,
      geoidalSeparation: separation,
      DGPSAge: dAge,
      DGPSReferenceStationID: dReferenceID,
      status: status
    )
  }
}
