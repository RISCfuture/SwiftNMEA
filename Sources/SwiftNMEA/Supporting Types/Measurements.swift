import Foundation

/// A true or magnetic bearing or heading.
public struct Bearing: Sendable, Codable, Equatable, Hashable {

    /// The angle from the north reference, increasing clockwise.
    public let angle: Measurement<UnitAngle>

    /// The 0° north reference.
    public let reference: Reference

    /**
     Creates a Bearing wiith an angle and reference.

     - Parameter angle: The bearing angle from the reference.
     - Parameter reference: The 0° reference.
     */
    public init(angle: Measurement<UnitAngle>, reference: Reference) {
        self.angle = angle
        self.reference = reference
    }

    /**
     Creates a Bearing wiith an angle (in degrees) and reference.

     - Parameter degrees: The bearing angle (in degrees) from the reference.
     - Parameter reference: The 0° reference.
     */
    public init(degrees: Double, reference: Reference) {
        self.init(angle: .init(value: degrees, unit: .degrees),
                  reference: reference)
    }

    /**
     Converts this bearing from magnetic to true. Returns `nil` if
     ``reference-swift.property`` is ``Reference-swift.enum/relative``.

     - Parameter variation: Magnetic variation (negative is east).
     - Returns: The true bearing, or `self` if ``reference-swift.property`` is
       already ``Reference-swift.enum/true``.
     */
    public func toTrue(variation: Measurement<UnitAngle>) -> Self? {
        switch reference {
            case .true: return self
            case .relative: return nil
            case .magnetic: return .init(angle: angle + variation, reference: .true)
        }
    }

    /**
     Converts this bearing from true to magnetic. Returns `nil` if
     ``reference-swift.property`` is ``Reference-swift.enum/relative``.

     - Parameter variation: Magnetic variation (negative is east).
     - Returns: The magnetic bearing, or `self` if ``reference-swift.property``
       is already ``Reference-swift.enum/magnetic``.
     */
    public func toMagnetic(variation: Measurement<UnitAngle>) -> Self? {
        switch reference {
            case .true: return .init(angle: angle - variation, reference: .magnetic)
            case .relative: return nil
            case .magnetic: return self
        }
    }

    /// A 0° north reference.
    public enum Reference: Character, Sendable, Codable {

        /// Bearing is referenced from the Magnetic North Pole.
        case magnetic = "M"

        /// Bearing is referenced from the true North Pole.
        case `true` = "T"

        /// Bearing is referenced from ship's true heading.
        case relative = "R"
    }
}

/**
 Reference headings for relative wind.

 Example 1: If the vessel is heading west at 7 knots and the wind is from the
 east at 10 knots the relative wind is 3 knots at 180°. In this same example the
 theoretical wind is 10 knots at 180° (if the boat suddenly stops the wind will
 be at the full 10 knots and come from the stern of the vessel 180° from the bow).

 Example 2: If the vessel is heading west at 5 knots and the wind is from the
 southeast at 7,07 knots the relative wind is 5 knots at 270°. In this same
 example the theoretical wind is 7,07 knots at 225° (if the boat suddenly stops
 the wind will be at the full 7,07 knots and come from the port-quarter of the
 vessel 225° from the bow).

 - SeeAlso: ``Message/Payload-swift.enum/windAngleSpeed(angle:speed:reference:isValid:)``
 */
public enum RelativeWindReference: Character, Sendable, Codable, Equatable {

    /**
     Data is provided giving the wind angle in relation to the vessel's
     bow/centreline and the wind speed, both relative to the (moving) vessel.
     Also called _apparent wind_, this is the wind speed as felt when standing
     on the (moving) ship.
     */
    case relative = "R"

    /**
     Data is provided giving the wind angle in relation to the vessel's
     bow/centreline and the wind speed as if the vessel was stationary. On a
     moving ship, these data can be calculated by combining the measured
     relative wind with the vessel's own speed.
     */
    case theoretical = "T"
}

/**
 Reference systems on which the calculation of vessel course and speed is based.

 The values of course and speed are derived directly from the referenced system
 and do not additionally include the effects of data in the set and drift
 fields.

 - SeeAlso: ``Message/Payload-swift.enum/ownshipData(heading:headingValid:course:courseReference:speed:speedReference:set:drift:)``
 */
public enum CourseSpeedReference: Character, Sendable, Codable, Equatable {

    /// Bottom tracking log
    case bottom = "B"

    /// Manually entered
    case manual = "M"

    /// Water referenced
    case water = "W"

    /// Radar tracking (of fixed target)
    case radar = "R"

    /// Positioning system ground reference.
    case ground = "P"
}

/**
 A heading sensor selected for display by an HMS.

 - SeeAlso: ``Message/Payload-swift.enum/headingMonitorReceive(sensor1:sensor2:setDifference:difference:differenceOK:variation:)``
 - SeeAlso: ``Message/Payload-swift.enum/headingMonitorSet(sensor1:sensor2:maxDiff:)``
 */
public struct HeadingSensor: Sendable, Codable, Equatable, Identifiable {

    /// Heading sensor, ID
    public let id: String

    /// Actual heading reading, degrees
    public let heading: Bearing

    /// Heading sensor status, valid or invalid data
    public let isValid: Bool

    /// Sensor deviation, degrees E/W, if known
    public let deviation: Measurement<UnitAngle>?
}

/**
 X , Y and Z coordination system.

 Origin (0,0) is located at the centre of the ship’s aft most point.

 - SeeAlso: ``Message/Payload-swift.enum/positionDimensions(equipment:equipmentNumber:positionValid:position:dimensionsValid:dimensions:status:)``
 */
public struct Coordinate: Sendable, Codable, Equatable {

    /// X-component: positive value (starboard), negative value (port) or zero
    ///  (centre).
    public let x: Measurement<UnitLength>

    /// Y-component: positive value or zero (forward distance from the ship’s
    ///  stern).
    public let y: Measurement<UnitLength>

    /// Z-component: positive value (height from IMO summer load line, see IMO
    ///  International Convention on Load Lines).
    public let z: Measurement<UnitLength>
}

/**
 Ship's length and width.

 - SeeAlso: ``Message/Payload-swift.enum/positionDimensions(equipment:equipmentNumber:positionValid:position:dimensionsValid:dimensions:status:)``
 */
public struct Dimensions: Sendable, Codable, Equatable {

    /// Ship’s length. The ship’s length corresponds to maximum overall length.
    public let length: Measurement<UnitLength>

    /// Ship’s width
    public let width: Measurement<UnitLength>
}

/**
 A bearing and range to a point.
 */
public struct BearingRange: Sendable, Codable, Equatable {
    public let bearing: Bearing
    public let range: Measurement<UnitLength>
}

/**
 A longitudinal and transverse speed.

 - SeeAlso: ``Message/Payload-swift.enum/speedData(water:waterValid:ground:groundValid:sternTransverseWater:sternTransverseWaterValid:sternTransverseGround:sternTransverseGroundValid:)``
 */
public struct SpeedVector: Sendable, Codable, Equatable {

    /// Longitudinal speed: "-" = astern
    public let longitudinal: Measurement<UnitSpeed>

    /// Transverse speed: "-" = port
    public let transverse: Measurement<UnitSpeed>
}
