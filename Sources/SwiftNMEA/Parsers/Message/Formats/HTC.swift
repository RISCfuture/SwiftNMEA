import Foundation
import NMEACommon
import NMEAUnits

class HTCParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .headingControlCommand
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let overrideOn = try sentence.fields.bool(at: 0)!,
            rudderAngle = try sentence.fields.measurement(at: 1, valueType: .float, units: UnitAngle.degrees, optional: true),
            isLeft = try sentence.fields.bool(at: 2, trueValue: "L", falseValue: "R", optional: true),
            mode = try sentence.fields.enumeration(at: 3, ofType: Steering.Mode.self)!,
            turnMode = try sentence.fields.enumeration(at: 4, ofType: Steering.TurnControl.self, optional: true),
            rudderLimit = try sentence.fields.measurement(at: 5, valueType: .float, units: UnitAngle.degrees, optional: true),
            offHeadingLimit = try sentence.fields.measurement(at: 6, valueType: .float, units: UnitAngle.degrees, optional: true),
            radius = try sentence.fields.measurement(at: 7, valueType: .float, units: UnitLength.nauticalMiles, optional: true),
            rate = try sentence.fields.measurement(at: 8, valueType: .float, units: UnitAngularVelocity.degreesPerMinute, optional: true),
            headingToSteer = try sentence.fields.bearing(at: 9, valueType: .float, referenceIndex: 12, optional: true),
            offTrackLimit = try sentence.fields.measurement(at: 10, valueType: .float, units: UnitLength.nauticalMiles, optional: true),
            track = try sentence.fields.bearing(at: 11, valueType: .float, referenceIndex: 12, optional: true),
            status = try sentence.fields.enumeration(at: 13, ofType: SentenceType.self)!

        return .headingControlCommand(heading: headingToSteer,
                                      track: track,
                                      rudderAngle: zipOptionals(rudderAngle, isLeft).map { $1 ? $0 * -1 : $0 },
                                      override: overrideOn,
                                      mode: mode,
                                      turnMode: turnMode,
                                      rudderLimit: rudderLimit,
                                      headingLimit: offHeadingLimit,
                                      trackLimit: offTrackLimit,
                                      radius: radius,
                                      rate: rate,
                                      status: status)
    }
}
