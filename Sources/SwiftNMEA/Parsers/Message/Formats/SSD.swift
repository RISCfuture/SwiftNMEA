import Foundation
import NMEAUnits

class SSDParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .AISShipStaticData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let callsignStr = try sentence.fields.string(at: 0, optional: true)
    let nameStr = try sentence.fields.string(at: 1)!
    let pointAValue = try sentence.fields.measurement(
      at: 2,
      valueType: .integer,
      units: UnitLength.meters,
      optional: true
    )
    let pointBValue = try sentence.fields.measurement(
      at: 3,
      valueType: .integer,
      units: UnitLength.meters,
      optional: true
    )
    let pointCValue = try sentence.fields.measurement(
      at: 4,
      valueType: .integer,
      units: UnitLength.meters,
      optional: true
    )
    let pointDValue = try sentence.fields.measurement(
      at: 5,
      valueType: .integer,
      units: UnitLength.meters,
      optional: true
    )
    let DTEAvailable = try sentence.fields.bool(at: 6, trueValue: "0", falseValue: "1")!
    let source = try sentence.fields.enumeration(at: 7, ofType: Talker.self)!

    let callsign = AIS.Availability(callsignStr, placeholder: "@@@@@@@")
    let name = AIS.Availability(nameStr, placeholder: "@@@@@@@@@@@@@@@@@@@@")
    let pointA = AIS.Availability(pointAValue) { $0.value == 0 }
    let pointB = AIS.Availability(pointBValue) { $0.value == 0 }
    let pointC = AIS.Availability(pointCValue) { $0.value == 0 }
    let pointD = AIS.Availability(pointDValue) { $0.value == 0 }

    return .AISShipStaticData(
      callsign: callsign,
      name: name,
      pointA: pointA,
      pointB: pointB,
      pointC: pointC,
      pointD: pointD,
      DTEAvailable: DTEAvailable,
      source: source
    )
  }
}
