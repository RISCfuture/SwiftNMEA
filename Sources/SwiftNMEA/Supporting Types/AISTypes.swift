import Foundation

// swiftlint:disable:next missing_docs
public struct AIS {
    private init() {}

    /**
     Acknowledgements provided for `ABK` messages.

     - SeeAlso: ``Message/Payload-swift.enum/AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     */
    public enum AcknowledgementType: Int, Sendable, Codable, Equatable {

        /// Message (6 or 12) successfully received by the addressed AIS unit.
        case received = 0

        /// Message (6 or 12) was broadcast, but no acknowledgement by the addressed
        /// AIS unit.
        case noAck = 1

        /// Message could not be broadcast (i.e. quantity of encapsulated data
        /// exceeds five slots).
        case broadcastFailed = 2

        /// Requested broadcast of Message (8, 14 or 15) has been successfully
        /// completed.
        case broadcastComplete = 3

        /// Late reception of a Message 7 or 13 acknowledgement that was addressed
        /// to this AIS unit (own ship) and referenced as a valid transaction.
        case lateReception = 4

        /// Message has been read and acknowledged on a display unit.
        case acknowledged = 5
    }

    /**
     The AIS channel that is to be used for a broadcast.

     - SeeAlso: ``Message/Payload-swift.enum/AISBinaryMessage(sequentialIdentifier:MMSI:channel:messageID:data:)``
     - SeeAlso: ``Message/Payload-swift.enum/broadcastMessage(sequence:AISChannel:MMSI:messageID:messageIndex:broadcastBehavior:destinationMMSI:binaryStructure:sentenceType:data:)``
     */
    public enum BroadcastChannel: Int, Sendable, Codable, Equatable {

        /// No broadcast channel preference.
        case noPreference = 0

        /// Broadcast on AIS channel A.
        case A = 1

        /// Broadcast on AIS channel B.
        case B = 2

        /// Broadcast message on both AIS channels, A and B.
        case both = 3
    }

    /**
     Possible values for channel bandwidths in `ACA` messages.

     - SeeAlso: ``Message/Payload-swift.enum/AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    public enum ChannelBandwidth: Int, Sendable, Codable, Equatable {

        /// Bandwidth is specified by channel number; see ITU-R M.1084, Annex 4.
        case byChannelNumber = 0

        /// Bandwidth is 12.5 kHz.
        case kHZ_12_5 = 1
    }

    /**
     Possible values for Tx/Rx mode control in `ACA` messages.

     - SeeAlso: ``Message/Payload-swift.enum/AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    public enum TransmitReceiveMode: Int, Sendable, Codable, Equatable {

        /// Transmit on channels A and B, receive on channels A and B.
        case transmitReceiveBoth = 0

        /// Transmit on channel A, receive on channels A and B.
        case transmitA_receiveBoth = 1

        /// Transmit on channel B, receive on channels A and B.
        case transmitB_receiveBoth = 2

        /// Do not transmit, receive on channels A and B.
        case noTransmit_receiveBoth = 3

        /// Do not transmit, receive on channel A.
        case noTransmit_receiveA = 4

        /// Do not transmit, receive on channel B.
        case noTransmit_receiveB = 5
    }

    /**
     Possible values for power levels in `ACA` messages.

     - SeeAlso: ``Message/Payload-swift.enum/AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    public enum PowerLevel: Int, Sendable, Codable, Equatable {

        /// High power.
        case high = 0

        /// Low power.
        case low = 1
    }

    /**
     Possible values for information source in `ACA` messages.

     - SeeAlso: ``Message/Payload-swift.enum/AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    public enum InformationSource: Character, Sendable, Codable, Equatable {

        /// ITU-R M.1371 Message 22: Channel Management addressed message.
        case message22Addressed = "A"

        /// ITU-R M.1371 Message 22: Channel Management broadcast geographical area
        /// message.
        case message22Broadcast = "B"

        /// IEC 61162-1 AIS Channel Assignment sentence.
        case AISAssignmentSentence = "C"

        /// DSC Channel 70 telecommand.
        case DSCChannel70 = "D"

        /// Operator manual input.
        case manualInput = "M"
    }

    /**
     An ITU-R M.1371 message and subsection requested as part of an `AIR` sentence.

     - SeeAlso: ``Message/Payload-swift.enum/AISInterrogationRequest(station1:station1Request1:station1Request2:station2:station2Request:channel:)``
     */
    public struct MessageRequest: Sendable, Codable, Equatable {

        /**
         Message number requested from station. See ITU-R M.1371 Message 15 and
         Message 10 description for the actual message numbers.
         */
        public let number: Int

        /**
         This field is used to request a message that has been further sub-divided
         into alternative data structures. When requesting a message with
         alternative data structures, this message sub-section field should be
         provided, so that the correct sub-division of the message data is provided.
         If the message structure is not sub-divided into different structures, this
         field should be `nil`.
         */
        public let subsection: Int?

        /**
         Start slot number of interrogation reply, 0 to 2249. `nil` if interrogation
         reply slot is not being assigned. AIS mobile stations should ignore this
         data field.
         */
        public let replySlot: Int?

        init(number: Int, subsection: Int?, replySlot: Int?) {
            self.number = number
            self.subsection = subsection
            self.replySlot = replySlot
        }

        init?(ID: String, replySlot: Int?) {
            let parts = ID.split(separator: ".")
            switch parts.count {
                case 1:
                    guard let number = Int(parts[0]) else { return nil }
                    self.number = number
                    self.subsection = nil
                case 2:
                    guard let number = Int(parts[0]),
                          let subsection = Int(parts[1]) else { return nil }
                    self.number = number
                    self.subsection = subsection
                default:
                    return nil
            }

            self.replySlot = replySlot
        }
    }

    /**
     A channel of interrogation for an AIS interrogation request.

     - SeeAlso: ``Message/Payload-swift.enum/AISInterrogationRequest(station1:station1Request1:station1Request2:station2:station2Request:channel:)``
     - SeeAlso: ``Message/Payload-swift.enum/AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     */
    public enum Channel: Character, Sendable, Codable, Equatable {

        /// Channel A
        case A = "A"

        /// Channel B
        case B = "B"
    }

    /// Possible message IDs, from ITU-R M.1371-5.
    public enum MessageID: Int, Sendable, Codable, Equatable {

        /// 3.1 Messages 1: Position reports (SOTDMA)
        case positionReportSOTDMA = 1

        /// 3.1 Messages 1: Position reports (SOTDMA)
        case positionReportSOTDMA_2 = 2

        /// 3.1 Messages 1: Position reports (ITDMA)
        case positionReportITDMA = 3

        /// 3.2 Message 4: Base station report
        case baseStationReport = 4

        /// 3.3 Message 5: Ship static and voyage related data
        case shipVoyageData = 5

        /// 3.4 Message 6: Addressed binary message
        case addressedBinary = 6

        /// 3.5 Message 7: Binary acknowledge
        case binaryAcknowledge = 7

        /// 3.6 Message 8: Binary broadcast message
        case broadcastBinary = 8

        /// 3.7 Message 9: Standard search and rescue aircraft position report
        case positionReportSAR = 9

        /// 3.8 Message 10: Coordinated universal time and date inquiry
        case UTCInquiry = 10

        /// 3.2 Message 11: Mobile station report
        case mobileStationReport = 11

        /// 3.10 Message 12: Addressed safety related message
        case addressedSafety = 12

        /// 3.5 Message 13: Safety related acknowledge
        case safetyAcknowledge = 13

        /// 3.12 Message 14: Safety related broadcast message
        case broadcastSafety = 14

        /// 3.13 Message 15: Interrogation
        case interrogation = 15

        /// 3.14 Message 16: Assigned mode command
        case assignedMode = 16

        /// 3.15 Message 17: Global navigation-satellite system broadcast binary message
        case broadcastBinaryGNSS = 17

        /// 3.16 Message 18: Standard class B equipment position report
        case positionReportClassB = 18

        /// 3.17 Message 19: Extended class B equipment position report
        case extendedPositionReportClassB = 19

        /// 3.18 Message 20: Data link management message
        case datalinkManagement = 20

        /// 3.19 Message 21: Aids-to-navigation report
        case aidsToNavigation = 21

        /// 3.20 Message 22: Channel management
        case channelManagement = 22

        /// 3.21 Message 23: Group assignment command
        case groupAssignment = 23

        /// 3.22 Message 24: Static data report
        case staticData = 24

        /// 3.23 Message 25: Single slot binary message
        case singleSlotBinary = 25

        /// 3.24 Message 26: Multiple slot binary message with communications state
        case multiSlotBinary = 26

        /// 3.25 Message 27: Long-range automatic identification system broadcast message
        case LRITBroadcast = 27
    }

    /**
     Broadcast behaviors for binary messages.

     - SeeAlso: ``Message/Payload-swift.enum/broadcastMessage(sequence:AISChannel:MMSI:messageID:messageIndex:broadcastBehavior:destinationMMSI:binaryStructure:sentenceType:data:)``
     */
    public enum BroadcastBehavior: Int, Sendable, Codable, Equatable {
        /// For an AtoN device, the message is stored for autonomous continuous
        /// transmission as defined by a `CBR` sentence. The message is
        /// identified by the combination of MMSI, Message ID, and Message ID
        /// Index.
        case store = 0

        /// For an AIS Class A device, a single transmission within 4 s
        /// according to RATDMA rules.
        case single = 1
    }

    /**
     Binary data types.

     - SeeAlso: ``Message/Payload-swift.enum/broadcastMessage(sequence:AISChannel:MMSI:messageID:messageIndex:broadcastBehavior:destinationMMSI:binaryStructure:sentenceType:data:)``
     */
    public enum BinaryDataStructure: Int, Sendable, Codable, Equatable {

        /// Unstructured binary data (no application identifier bits used).
        case unstructured = 0

        /// Binary data coded as defined by using the 16-bit application
        /// identifier (see ITU-R M.1371, messages 25 and 26).
        case application = 1
    }

    /**
     AIS ship data (name, callsign) that can either be available or unavailable.

     - SeeAlso: ``Message/Payload-swift.enum/AISShipStaticData(callsign:name:pointA:pointB:pointC:pointD:DTEAvailable:source:)``
     */
    public enum Availability<RawValue> {

        /// The data is not available
        case unavailable

        /// The data is available
        case available(_ value: RawValue)

        /// The value if ``available(_:)``, or `nil` if ``unavailable``.
        public var value: RawValue? {
            switch self {
                case .unavailable: nil
                case let .available(value): value
            }
        }

        /// `true` if ``available(_:)``, `false` if ``unavailable``.
        public var isAvailable: Bool {
            switch self {
                case .unavailable: false
                case .available: true
            }
        }

        init(_ value: RawValue, unavailableWhen: (RawValue) -> Bool) {
            if unavailableWhen(value) { self = .unavailable }
            else { self = .available(value) }
        }

        init?(_ value: RawValue?, unavailableWhen: (RawValue) -> Bool) {
            guard let value else { return nil }
            if unavailableWhen(value) { self = .unavailable }
            else { self = .available(value) }
        }
    }

    /**
     Navigational statuses, from ITU-R M.1371, Message 1.

     - SeeAlso: ``Message/Payload-swift.enum/AISVoyageData(shipType:maxDraft:soulsOnboard:destination:destinationETA:navStatus:regionalFlags:)``
     */
    public enum NavigationalStatus: Int, Sendable, Codable, Equatable {

        /// Under way using engine
        case underway = 0

        /// At anchor
        case atAnchor = 1

        /// Not under command
        case notUnderCommand = 2

        /// Restricted manoeuvrability
        case restricted = 3

        /// Constrained by draught
        case draughtConstrained = 4

        /// Moored
        case moored = 5

        /// Aground
        case aground = 6

        /// Engaged in fishing
        case fishing = 7

        /// Under way sailing
        case sailing = 8

        /// Reserved for High Speed Craft (HSC)
        case highSpeedCraft = 9

        /// Reserved for Wing In Ground (WIG)
        case wingInGround = 10

        /// Default
        case `default` = 15
    }

    /**
     A set of date components (``month``, ``day``, ``hour``, and ``minute``)
     along with their availability flags.

     AIS data is typically in one of three states: available, unavailable, or
     unchanged. This is normally represented by the ``Availability`` enum, with
     `nil` representing unchanged data. For ETA information, any one of the date
     components (``month``, ``day``, ``hour``, or ``minute``) may be available,
     unavailable, or unchanged, with different availabilities for different
     parts of the date.

     The ``components`` field represents the `DateComponents` object built from
     the availability fields. Only the `month`, `day`, `hour`, and `minute`
     fields of ``components`` will be specified; all others will be `nil`. If
     one of the `month`, `day`, `hour`, or `minute` fields is `nil`, that means
     that data is unchanged or unavailable.

     - SeeAlso: ``Message/Payload-swift.enum/AISVoyageData(shipType:maxDraft:soulsOnboard:destination:destinationETA:navStatus:regionalFlags:)``
     */
    public struct DateAvailability: Sendable, Codable, Equatable {

        /// The month of the year (1–12). `nil` if unchanged from previous value.
        public let month: AIS.Availability<Int>?

        /// The day of the month (1–31). `nil` if unchanged from previous value.
        public let day: AIS.Availability<Int>?

        /// The hour of the day (0–23). `nil` if unchanged from previous value.
        public let hour: AIS.Availability<Int>?

        /// The minute of the hour (0–59). `nil` if unchanged from previous value.
        public let minute: AIS.Availability<Int>?

        /// The date components. Only `month`, `day`, `hour`, and `minute` are
        /// specified. If any of those fields is `nil`, the data is unavailable
        /// or unchanged. Other fields are always `nil`.
        public var components: DateComponents {
            .init(calendar: .init(identifier: .gregorian),
                  timeZone: .gmt,
                  month: month?.value,
                  day: day?.value,
                  hour: hour?.value,
                  minute: minute?.value)
        }
    }
}

extension AIS.Availability: Sendable where RawValue: Sendable {}
extension AIS.Availability: Codable where RawValue: Codable {}

extension AIS.Availability: Equatable where RawValue: Equatable {
    init(_ value: RawValue, placeholder: RawValue) {
        self.init(value) { $0 == placeholder }
    }

    init?(_ value: RawValue?, placeholder: RawValue) {
        guard let value else { return nil }
        self.init(value) { $0 == placeholder }
    }
}
