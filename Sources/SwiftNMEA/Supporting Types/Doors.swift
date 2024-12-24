// swiftlint:disable:next missing_docs
public struct Doors {
    private init() {}

    /**
     The type of `DOR` sentence being transmitted.

     - SeeAlso: ``Message/Payload-swift.enum/doorStatus(messageType:time:systemType:division1:division2:doorNumber:doorStatus:switchSetting:description:)``
     - SeeAlso: ``Message/Payload-swift.enum/waterLevel(messageType:time:systemType:location1:location2:number:alarmCondition:isOverriden:description:)``
     */
    public enum MessageType: Character, Sendable, Codable, Equatable {

        /**
         Status for section: the number of faulty and/or open doors reported in
         the division specified. The section may be a whole section (one or
         both of the division indicator fields are null) or a sub-section.
         Normally transmitted at regular intervals. Examples of use are given in
         Annex E.
         */
        case section = "S"

        /// Status for single door. (May be used to indicate an event).
        case event = "E"

        /// Fault in system: Division indicator fields defines the section when
        /// provided.
        case fault = "F"
    }

    /**
     Types of door monitoring systems. The meaning of the "first division" and
     "second division" fields of the `DOR` sentence depend on the value of this
     type.

     - SeeAlso: ``Message/Payload-swift.enum/doorStatus(messageType:time:systemType:division1:division2:doorNumber:doorStatus:switchSetting:description:)``
     */
    public enum SystemType: String, Sendable, Codable, Equatable {

        /**
         Watertight door

         - First division indicator: Number of watertight bulkhead / frame number
         - Second division indicator: Deck number
         */
        case watertight = "WT"

        /**
         Semi-watertight door (splash-tight)

         - First division indicator: Number of watertight bulkhead / frame number
         - Second division indicator: Deck number
         */
        case semiWatertight = "WS"

        /**
         Fire door

         - First division indicator: Number / letter of zone. This can also be
           identifier for control and monitoring main system.
         - Second division indicator: Deck number or control system loop number
           or other control system division indicator as is appropriate for system
         */
        case fire = "FD"

        /**
         Hull (shell) door

         - First division indicator: Door indication number / frame number
         - Second division indicator: Deck number
         */
        case hull = "HD"

        /// Other
        case other = "OT"
    }

    /**
     Door statuses.

     - SeeAlso: ``Message/Payload-swift.enum/doorStatus(messageType:time:systemType:division1:division2:doorNumber:doorStatus:switchSetting:description:)``
     */
    public enum Status: Character, Sendable, Codable, Equatable {

        /// Open
        case open = "O"

        /// Closed
        case closed = "C"

        /// Secured
        case secured = "S"

        /// Free status (for watertight door)
        case free = "F"

        /// Fault (door status unknown)
        case fault = "X"
    }

    /**
     Water tight door switch settings.

     - SeeAlso: ``Message/Payload-swift.enum/doorStatus(messageType:time:systemType:division1:division2:doorNumber:doorStatus:switchSetting:description:)``
     */
    public enum SwitchSetting: Character, Sendable, Codable, Equatable {

        /// Harbour mode (allowed open)
        case harborMode = "O"

        /// Sea mode (ordered closed)
        case seaMode = "C"
    }
}
