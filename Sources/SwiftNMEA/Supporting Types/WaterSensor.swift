// swiftlint:disable:next missing_docs
public struct WaterSensor {
    private init() {}

    /**
     A method of ship speed used for measuring the current speed.

     - SeeAlso: ``Message/Payload-swift.enum/currentWaterLayer(isValid:setNumber:layer:depth:direction:speed:referenceDepth:heading:speedReference:)``
     */
    public enum SpeedReference: Character, Sendable, Codable, Equatable {

        /// Bottom track
        case bottomTrack = "B"

        /// Water track
        case waterTrack = "W"

        /// Positioning system
        case positioningSystem = "P"
    }

    /**
     Water level sensor types.

     - SeeAlso: ``Message/Payload-swift.enum/waterLevel(messageType:time:systemType:location1:location2:number:alarmCondition:isOverriden:description:)``
     */
    public enum SystemType: String, Sendable, Codable, Equatable {

        /// Water level detection system
        case waterLevel = "WL"

        /// High water level by bilge system
        case bilgeHigh = "BI"

        /// Water leakage at hull (shell) door
        case hullDoorLeakage = "HD"

        /// others
        case others = "OT"
    }

    /**
     Water level sensor statuses.

     - SeeAlso: ``Message/Payload-swift.enum/waterLevel(messageType:time:systemType:location1:location2:number:alarmCondition:isOverriden:description:)``
     */
    public enum Status: Character, Sendable, Codable, Equatable {

        /// Normal state
        case normal = "N"

        /// Alarm state (threshold exceeded)
        case alarmHigh = "H"

        /// Alarm state (extreme threshold exceeded)
        case alarmExtremeHigh = "J"

        /// Alarm state (low threshold exceeded, i.e. not reached)
        case alarmLow = "L"

        /// Alarm state (extreme low threshold exceeded, i.e. not reached)
        case alarmExtremeLow = "K"

        /// Fault (state unknown)
        case fault = "X"
    }
}
