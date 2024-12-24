// swiftlint:disable:next missing_docs
public struct Navigation {
    private init() {}

    /**
     Possible positioning system modes.

     - SeeAlso: ``Message/Payload-swift.enum/autopilotSentenceB(LORANC_blinkSNRFlag:LORANC_cycleLockWarningFlag:crossTrackError:arrivalCircleEntered:perpendicularPassed:bearingOriginToDest:destinationID:bearingPresentPosToDest:headingToDest:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/geoPosition(_:time:isValid:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     - SeeAlso: ``Message/Payload-swift.enum/LORANCMinimumData(isValid:position:timeDifferenceA:timeDifferenceB:speed:course:magneticVariation:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/destinationMinimumData(isValid:crossTrackError:originID:destinationID:destination:rangeToDestination:bearingToDestination:closingVelocity:isArrived:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/groundSpeedCourse(courseTrue:courseMagnetic:speedKnots:speedKph:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/waypointClosure(_:identifier:mode:)``
     - SeeAlso: ``Message/Payload-swift.enum/crossTrackError(_:mode:LORANC_blinkSNRFlag:LORANC_cycleLockWarningFlag:)``
     */
    public enum Mode: Character, Sendable, Codable, Equatable {

        /// Autonomous mode
        case autonomous = "A"

        /// Differential mode
        case differential = "D"

        /// Estimated (dead reckoning) mode
        case estimated = "E"

        /// Manual input mode
        case manual = "M"

        /// Precise. Satellite system used in precision mode. Precision mode is
        /// defined as: no deliberate degradation (such as selective
        /// availability) and higher resolution code (P-code) is used to compute
        /// position fix. `precise` is also used for satellite system used in
        /// multi-frequency, SBAS or Precise Point Positioning (PPP) mode.
        case precise = "P"

        /// Simulator mode
        case simulator = "S"

        /// Data not valid or not in use
        case invalid = "N"

        /// Real Time Kinematic. Satellite system used in RTK mode with fixed
        /// integers.
        case RTK = "R"

        /// Float RTK. Satellite system used in real time kinematic mode with
        /// floating integers.
        case floatRTK = "F"
    }

    /**
     Route modes of transmission.

     - SeeAlso: ``Message/Payload-swift.enum/route(mode:identifier:waypoints:)``
     */
    public enum RouteType: Character, Sendable, Codable, Equatable {

        /// Complete route, all waypoints
        case complete = "c"

        /// Working route, first listed waypoint is "FROM", second is "TO" and
        /// remaining are rest of route
        case working = "w"
    }

    /**
     A calculated variable point.

     - SeeAlso: ``Message/Payload-swift.enum/timeDistanceToVariablePoint(time:distance:type:)``
     */
    public enum VariablePoint: Character, Sendable, Codable, Equatable {

        /// Collision
        case collision = "C"

        /// Turning point
        case turning = "T"

        /// Reference (general)
        case reference = "R"

        /// Wheel-over
        case wheelover = "W"
    }
}
