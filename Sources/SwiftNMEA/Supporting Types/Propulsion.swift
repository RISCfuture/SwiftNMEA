import Foundation
import NMEAUnits

// swiftlint:disable:next missing_docs
public struct Propulsion {
    private init() {}

    /**
     RPM demand or response values.

     - SeeAlso: ``Message/Payload-swift.enum/propulsionRemoteControl(leverDemandPosition:leverDemandValid:RPMDemand:pitchDemand:location:engineNumber:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterControl(number:RPM:pitch:azimuth:location:status:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterResponse(number:RPM:pitch:azimuth:)``
     */
    public enum RPMValue: Sendable, Codable, Equatable {

        /// Per cent (%): 0 to 100 % from zero to maximum rpm
        case percent(_ percent: Double)

        /// Revolutions per minute (rpm): "-" Astern
        case value(_ value: Measurement<UnitAngularVelocity>)

        /// Data invalid
        case invalid
    }

    /**
     Propeller pitch demand or response values.

     - SeeAlso: ``Message/Payload-swift.enum/propulsionRemoteControl(leverDemandPosition:leverDemandValid:RPMDemand:pitchDemand:location:engineNumber:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterControl(number:RPM:pitch:azimuth:location:status:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterResponse(number:RPM:pitch:azimuth:)``
     */
    public enum PitchValue: Sendable, Codable, Equatable {
        /// P = Per cent (%): −100 to 0 to 100 % from “full astern” (crash
        /// astern) to “full ahead” (navigation full) through “stop engine”
        case percent(_ percent: Double)

        /// Degrees: "-": Astern
        case value(_ value: Measurement<UnitAngle>)

        /// Data invalid
        case invalid
    }

    /**
     Possible engine control or telegraph locations.

     - SeeAlso: ``Message/Payload-swift.enum/engineTelegraph(time:type:position:subPosition:location:number:)``
     - SeeAlso: ``Message/Payload-swift.enum/propulsionRemoteControl(leverDemandPosition:leverDemandValid:RPMDemand:pitchDemand:location:engineNumber:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterControl(number:RPM:pitch:azimuth:location:status:)``
     - SeeAlso: ``Message/Payload-swift.enum/thrusterResponse(number:RPM:pitch:azimuth:)``
     */
    public enum Location: Character, Sendable, Codable, Equatable {

        /// Bridge
        case bridge = "B"

        /// Port wing
        case portWing = "P"

        /// Starboard wing
        case starboardWing = "S"

        /// Engine control room
        case controlRoom = "C"

        /// Engine side / local
        case engineLocal = "E"

        /// Wing (port or starboard not specified)
        case wing = "W"
    }

    /**
     Revolution rate or thrust data sources.

     - SeeAlso: ``Message/Payload-swift.enum/revolutions(source:number:speed:pitch:isValid:)``
     */
    public enum ThrustSource: Character, Sendable, Codable, Equatable {
        case shaft = "S"
        case engine = "E"
    }
}
