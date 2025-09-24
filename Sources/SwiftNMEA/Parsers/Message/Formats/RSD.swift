import Foundation
import NMEAUnits

class RSDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .radarSystemData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let range1 = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let bearing1 = try sentence.fields.bearing(at: 1, valueType: .float, reference: .relative)!
    let vrm1 = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let ebl1 = try sentence.fields.bearing(at: 3, valueType: .float, reference: .relative)!
    let range2 = try sentence.fields.measurement(
      at: 4,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let bearing2 = try sentence.fields.bearing(at: 5, valueType: .float, reference: .relative)!
    let vrm2 = try sentence.fields.measurement(
      at: 6,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let ebl2 = try sentence.fields.bearing(at: 7, valueType: .float, reference: .relative)!
    let cursorRange = try sentence.fields.measurement(
      at: 8,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let cursorBearing = try sentence.fields.bearing(at: 9, valueType: .float, reference: .relative)!
    let rangeScale = try sentence.fields.measurement(
      at: 10,
      valueType: .float,
      unitAt: 11,
      units: lengthUnits
    )!
    let rotation = try sentence.fields.enumeration(at: 12, ofType: DisplayRotation.self)!

    let origin1 = BearingRange(bearing: bearing1, range: range1)
    let origin2 = BearingRange(bearing: bearing2, range: range2)
    let cursor = BearingRange(bearing: cursorBearing, range: cursorRange)

    return .radarSystemData(
      origin1: origin1,
      VRM1: vrm1,
      EBL1: ebl1,
      origin2: origin2,
      VRM2: vrm2,
      EBL2: ebl2,
      cursor: cursor,
      rangeScale: rangeScale,
      rotation: rotation
    )
  }
}
