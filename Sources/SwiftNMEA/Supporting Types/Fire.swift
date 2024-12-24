// swiftlint:disable:next missing_docs
public struct Fire {
    private init() {}

    /**
     Fire detection message type.

     - SeeAlso: ``Message/Payload-swift.enum/fireDetection(type:time:detector:zone:loop:number:condition:isAcknowledged:description:)``
     */
    public enum MessageType: Character, Sendable, Codable, Equatable {

        /// Section message. The section may be a whole section or a
        /// sub-section. This status is normally transmitted at regular
        /// intervals.
        case section = "S"

        /// Status for each fire detector. (May be used to indicate an event.)
        case event = "E"

        /// Fault in system
        case fault = "F"

        /// Disabled: Detector is manually or automatically disabled from giving
        /// fire alarms.
        case disabled = "D"
    }

    /**
     Types of fire detectors.

     - SeeAlso: ``Message/Payload-swift.enum/fireDetection(type:time:detector:zone:loop:number:condition:isAcknowledged:description:)``
     */
    public enum DetectorType: String, Sendable, Codable, Equatable {

        /// Generic fire detector, can be any of the ones below
        case generic = "FD"

        /// Heat type detector
        case heat = "FH"

        /// Smoke type detector
        case smoke = "FS"

//        case smokeAndHeat = "FD"

        /// Manual call point
        case manual = "FM"

        /// Any gas detector
        case gas = "GD"

        /// Oxygen gas detector
        case oxygen = "GO"

        /// Hydrogen sulphide gas detector
        case H2S = "GS"

        /// Hydro-carbon gas detector
        case hydrocarbon = "GH"

        /// Sprinkler flow switch
        case sprinklerFlow = "SF"

        /// Sprinkler manual valve release
        case sprinklerValve = "SV"

        /// CO₂ manual release
        case CO2 = "CO"

        /// Other
        case other = "OT"
    }

    /**
     Fire detector condition.

     - SeeAlso: ``Message/Payload-swift.enum/fireDetection(type:time:detector:zone:loop:number:condition:isAcknowledged:description:)``
     */
    public enum DetectorCondition: Character, Sendable, Codable, Equatable {

        /// Activation
        case activation = "A"

        /// Non-activation
        case nonactivation = "V"

        /// Fault (state unknown)
        case fault = "X"
    }
}
