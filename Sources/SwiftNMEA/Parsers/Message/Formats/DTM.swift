import Foundation

class DTMParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws(NMEAError) -> Bool {
    sentence.delimiter == .parametric && sentence.format == .datumReference
  }

  func parse(sentence: ParametricSentence) throws(NMEAError) -> Message.Payload? {
    let localDatumStr = try sentence.fields.string(at: 0, optional: true)
    let localSubdivision = try sentence.fields.character(at: 1, optional: true)
    let latOffsetMag = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      units: UnitAngle.arcMinutes,
      optional: true
    )
    let latOffsetHemisphere = try sentence.fields.character(at: 3, optional: true)
    let lonOffsetMag = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      units: UnitAngle.arcMinutes,
      optional: true
    )
    let lonOffsetHemisphere = try sentence.fields.character(at: 5, optional: true)
    let altOffset = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      units: UnitLength.meters,
      optional: true
    )
    let referenceDatumStr = try sentence.fields.string(at: 7)!

    var localDatum: Datum?
    if let localDatumStr {
      guard let datum = Datum(rawValue: localDatumStr, subdivision: localSubdivision) else {
        throw sentence.fields.fieldError(type: .unknownValue, index: 0)
      }
      localDatum = datum
    }
    guard let referenceDatum = Datum(rawValue: referenceDatumStr) else {
      throw sentence.fields.fieldError(type: .unknownValue, index: 7)
    }

    // §8.3.31 footnote 3: when the local datum is user-defined (code 999), the
    // offset fields shall not be null.
    if case .userDefined = localDatum {
      if latOffsetMag == nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 2)
      }
      if latOffsetHemisphere == nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 3)
      }
      if lonOffsetMag == nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 4)
      }
      if lonOffsetHemisphere == nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 5)
      }
      if altOffset == nil {
        throw sentence.fields.fieldError(type: .missingRequiredValue, index: 6)
      }
    }

    var latOffset: Measurement<UnitAngle>?
    if let latOffsetMag {
      switch latOffsetHemisphere {
        case "N": latOffset = latOffsetMag
        case "S": latOffset = latOffsetMag * -1
        default: throw sentence.fields.fieldError(type: .badCharacterValue, index: 3)
      }
    }

    var lonOffset: Measurement<UnitAngle>?
    if let lonOffsetMag {
      switch lonOffsetHemisphere {
        case "E": lonOffset = lonOffsetMag
        case "W": lonOffset = lonOffsetMag * -1
        default: throw sentence.fields.fieldError(type: .badCharacterValue, index: 5)
      }
    }

    return .datumReference(
      localDatum: localDatum,
      latitudeOffset: latOffset,
      longitudeOffset: lonOffset,
      altitudeOffset: altOffset,
      referenceDatum: referenceDatum
    )
  }
}
