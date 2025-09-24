import Foundation

class APBParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .autopilotSentenceB
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let blinkFlag = try sentence.fields.bool(at: 0, trueValue: "V", falseValue: "A")!
    let cycleLockFlag = try sentence.fields.bool(at: 1, trueValue: "V", falseValue: "A")!
    let xte = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 4,
      units: lengthUnits
    )!
    let isLeft = try sentence.fields.bool(at: 3, trueValue: "L", falseValue: "R")!
    let arrivalCircleEntered = try sentence.fields.bool(at: 5)!
    let perpendicularPassed = try sentence.fields.bool(at: 6)!
    let bearingOriginToDest = try sentence.fields.bearing(
      at: 7,
      valueType: .float,
      referenceIndex: 8
    )!
    let destinationID = try sentence.fields.string(at: 9)!
    let bearingPPosToDest = try sentence.fields.bearing(
      at: 10,
      valueType: .float,
      referenceIndex: 11
    )!
    let headingToSteer = try sentence.fields.bearing(at: 12, valueType: .float, referenceIndex: 13)!
    let mode = try sentence.fields.enumeration(at: 14, ofType: Navigation.Mode.self)!

    return .autopilotSentenceB(
      LORANC_blinkSNRFlag: blinkFlag,
      LORANC_cycleLockWarningFlag: cycleLockFlag,
      crossTrackError: isLeft ? xte * -1 : xte,
      arrivalCircleEntered: arrivalCircleEntered,
      perpendicularPassed: perpendicularPassed,
      bearingOriginToDest: bearingOriginToDest,
      destinationID: destinationID,
      bearingPresentPosToDest: bearingPPosToDest,
      headingToDest: headingToSteer,
      mode: mode
    )
  }
}
