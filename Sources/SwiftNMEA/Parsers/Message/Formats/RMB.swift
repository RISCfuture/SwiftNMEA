import Foundation
import NMEAUnits

class RMBParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .destinationMinimumData
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let isValid = try sentence.fields.bool(at: 0)!
    let xte = try sentence.fields.measurement(
      at: 1,
      valueType: .float,
      units: UnitLength.nauticalMiles
    )!
    let isLeft = try sentence.fields.bool(at: 2, trueValue: "L", falseValue: "R")!
    let originID = try sentence.fields.string(at: 3)!
    let destID = try sentence.fields.string(at: 4)!
    let destPosition = try sentence.fields.position(latitudeIndex: (5, 6), longitudeIndex: (7, 8))!
    let rangeDest = try sentence.fields.measurement(
      at: 9,
      valueType: .float,
      units: UnitLength.nauticalMiles
    )!
    let bearingDest = try sentence.fields.bearing(at: 10, valueType: .float, reference: .true)!
    let closingVelocity = try sentence.fields.measurement(
      at: 11,
      valueType: .float,
      units: UnitSpeed.knots
    )!
    let isArrived = try sentence.fields.bool(at: 12)!
    let mode = try sentence.fields.enumeration(at: 13, ofType: Navigation.Mode.self)!

    return .destinationMinimumData(
      isValid: isValid,
      crossTrackError: isLeft ? xte * -1 : xte,
      originID: originID,
      destinationID: destID,
      destination: destPosition,
      rangeToDestination: rangeDest,
      bearingToDestination: bearingDest,
      closingVelocity: closingVelocity,
      isArrived: isArrived,
      mode: mode
    )
  }
}
