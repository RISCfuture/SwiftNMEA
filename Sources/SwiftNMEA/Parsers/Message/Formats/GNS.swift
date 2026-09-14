import Foundation
import NMEACommon

class GNSParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .GNSSFix
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
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

    var mode: [GNSS.System: Navigation.Mode]?
    if let modes {
      // ed.6.0 defines six mode-indicator characters: GPS, GLONASS, Galileo,
      // BDS, QZSS, NavIC. Shorter strings report only the leading systems.
      let systems: [GNSS.System] = [.GPS, .GLONASS, .galileo, .beidou, .QZSS, .navIC]
      var parsed = [GNSS.System: Navigation.Mode]()
      for (index, system) in systems.enumerated() {
        guard let char = modes.char(at: index) else { continue }
        guard let parsedMode = Navigation.Mode(rawValue: char) else {
          throw sentence.fields.fieldError(type: .unknownValue, index: 5)
        }
        parsed[system] = parsedMode
      }
      mode = parsed
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
