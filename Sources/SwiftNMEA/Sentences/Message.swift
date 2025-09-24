import Foundation
import NMEACommon
import NMEAUnits
import SwiftDSE

/// A message is constructed from one or more ``Sentence``s whose fields have
/// been parsed into a ``Payload-swift.enum``. The sentences must share the same
/// ``talker`` and ``format``.
///
/// If a Message cannot be parsed from a Sentence, a ``MessageError`` is generated
/// and added to the stream instead.
public struct Message: Element, Sendable, Codable, Equatable {

  /// The component that sent the message.
  public let talker: Talker

  /// The message format.
  public let format: Format

  /// The parsed message.
  public let payload: Payload

  /// Different types of NMEA messages and the data associated with them.
  public enum Payload: Sendable, Codable, Equatable {

    /**
     8.3.2 AAM – Waypoint arrival alarm
    
     Status of arrival (entering the arrival circle, or passing the
     perpendicular of the course line) at waypoint.
    
     - Parameter arrivalCircleEntered: `true` if the vehicle entered the arrival
     circle of the waypoint.
     - Parameter perpendicularPassed: `true` if the vehicle passed the
     waypoint's perpendicular to the course line.
     - Parameter arrivalCircleRadius: The radius of the arrival circle.
     - Parameter waypoint: The waypoint identifier.
     */
    case waypointArrivalAlarm(
      arrivalCircleEntered: Bool,
      perpendicularPassed: Bool,
      arrivalCircleRadius: Measurement<UnitLength>,
      waypoint: String
    )

    /**
     8.3.3 ABK – AIS addressed and binary broadcast acknowledgement
    
     The `ABK`-sentence is generated when a transaction, initiated by reception
     of an `ABM`, `AIR`, or `BBM` sentence, is completed or terminated. This
     sentence provides information about the success or failure of a requested
     `ABM` broadcast of either ITU-R M.1371 Messages 6 or 12. The `ABK` process
     utilises the information received in ITU-R M.1371 Messages 7 and 13. Upon
     reception of either a VHF Data-link Message 7 or 13, or the failure of
     Messages 6 or 12, the AIS unit delivers the ABK sentence to the external
     application. This sentence is also used to report to the external
     application the AIS unit’s handling of the `AIR` (ITU-R M.1371 Message 15)
     and `BBM` (ITU-R M.1371 Messages 8, 14, 19, and 21) sentences. The external
     application initiates an interrogation through the use of the
     `AIR`-sentence, or a broadcast through the use of the `BBM` sentence. The
     AIS unit generates an ABK sentence to report the outcome of the `ABM`,
     `AIR`, or `BBM` broadcast process.
    
     The `ABK` is also used as an input and output to indicate that a received
     Message 12 has been read and acknowledged on a display unit.
    
     - Parameter MMSI: Identifies the distant addressed AIS unit involved with
     the acknowledgement. If more than one MMSI is being addressed
     (ITU-R M.1371 Messages 15 and 16), the MMSI of the first distant AIS
     unit, identified in the message, is the MMSI reported here. This is a
     `nil` field when the ITU-R M.1371 Message type is 8 or 14.
     - Parameter channel: Indication of the VHF data link channel upon which a
     Message type 7 or 13 acknowledgement was received. An “A” indicates
     reception on channel A. A “B” indicates reception on channel B.
     - Parameter messageID: This indicates to the external application the type
     of ITU-R M.1371 message that this `ABK` sentence is addressing.
     - Parameter sequence: The message sequence number, together with the
     message ID and MMSI of the addressed AIS unit, uniquely identifies a
     previously received `ABM`, `AIR`, or `BBM` sentence. Generation of an
     `ABK` sentence makes a sequence message identifier available for re-use.
     The message ID determines the source of the message sequence number.
     - Parameter type: Acknowledgement type.
     - SeeAlso: ``AISBinaryMessage(sequentialIdentifier:MMSI:channel:messageID:data:)``
     - SeeAlso: ``AISInterrogationRequest(station1:station1Request1:station1Request2:station2:station2Request:channel:)``
     - SeeAlso: ``AISBroadcastBinaryMessage(sequentialIdentifier:channel:messageID:data:)``
     */
    case AISBroadcastAcknowledgement(
      MMSI: Int?,
      channel: AIS.Channel,
      messageID: String,
      sequence: Int?,
      type: AIS.AcknowledgementType
    )

    /**
     ABM – AIS addressed binary and safety related message
    
     This sentence supports ITU-R M.1371 Messages 6 and 12 and provides an
     external application with a means to exchange data via an AIS transponder.
     Data is defined by the application only, not the AIS unit. This message
     offers great flexibility for implementing system functions that use the
     transponder like a communications device. After receiving this sentence
     via the IEC 61162-2 interface, the transponder initiates a VDL broadcast of
     either Message 6 or 12. The AIS unit will make up to four broadcasts of the
     message. The actual number will depend on the reception of an
     acknowledgement from the addressed “destination” AIS unit. The success or
     failure of reception of this transmission by the addressed AIS unit is
     confirmed through the use of the “Addressed binary and safety related
     message acknowledgement” `ABK` sentence formatter, and the processes that
     support the generation of an `ABK` sentence.
    
     - Parameter sequentialIdentifier: This sequential message identifier serves
     two purposes. It meets the requirements as stated in 7.2.5 and it is the
     sequence number utilised by ITU-R M.1371 in Message types 6 and 12. The
     range of this field is restricted by ITU-R M.1371 to 0 – 3. The
     sequential message identifier value may be re-used after the AIS unit
     provides the `ABK` acknowledgement for this number.
     - Parameter MMSI: The MMSI of the destination AIS unit for the ITU-R M.1371
     Message 6 or 12.
     - Parameter channel: AIS channel for broadcast of the radio message.
     - Parameter messageID: ITU-R M.1371 Message ID (``AIS/MessageID/addressedBinary`` or ``AIS/MessageID/addressedSafety``).
     - Parameter data: This is the content of the “binary data” parameter for
     ITU-R M.1371 Messages 6, or the “Safety related Text” parameter for
     Message 12. Up to 936 bits of binary data (156 six-bit coded characters)
     using multi-line sentences.
     - SeeAlso: ``AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     */
    case AISBinaryMessage(
      sequentialIdentifier: Int,
      MMSI: Int?,
      channel: AIS.BroadcastChannel?,
      messageID: AIS.MessageID?,
      data: Data
    )

    /**
     8.3.5 ACA – AIS channel assignment message
    
     An AIS device can receive regional channel management information in four
     ways: ITU-R M.1371 Message 22, DSC telecommand received on channel 70,
     manual operator input, and an `ACA` sentence. The AIS unit may store
     channel management information for future use. Channel management
     information is applied based upon the actual location of the AIS device.
     An AIS unit is “using” channel management information when the information
     is being used to manage the operation of the VHF receiver and/or
     transmitter inside the AIS unit.
    
     This sentence is used both to enter and obtain channel management
     information. When sent to an AIS unit, the `ACA` sentence provides regional
     information that the unit stores and uses to manage the internal VHF radio.
     When sent from an AIS unit, the `ACA` sentence provides the current channel
     management information retained by the AIS unit. The information contained
     in this sentence is similar to the information contained in an ITU-R M.1371
     Message 22. The information contained in this sentence directly relates to
     the initialisation phase and dual channel operation and channel management
     functions of the AIS unit as described in ITU-R M.1371.
    
     - Parameter sequenceNumber: This is used to bind the contents of the `ACA`
     and `ACS` sentences together. The `ACS` sentence, when provided by the
     AIS unit, should immediately follow the related `ACA` sentence,
     containing the same sequence number. The AIS unit generating the `ACA`
     and `ACS` sentences, should increment the sequence number each time an
     `ACA`/`ACS` pair is created. After 9 is used the process should begin
     again from 0. Information contained in the `ACS` sentence is not related
     to the information of the `ACA` sentence if the sequence numbers are
     different. When an external device is sending an `ACA` sentence to the
     AIS unit, the sequence number may be `nil` if no `ACS` sentence is being
     sent.
     - Parameter northeastCorner: Region northeast corner
     - Parameter southwestCorner: Region southwest corner
     - Parameter transitionZoneSize: Transition zone size
     - Parameter channelA: Channel A, VHF channel number
     - Parameter channelABandwidth: Channel A bandwidth
     - Parameter channelB: Channel B, VHF channel number
     - Parameter channelBBandwidth: Channel B bandwidth
     - Parameter txRxMode: Tx/Rx mode control
     - Parameter powerLevel: Power level control
     - Parameter source: Information source
     - Parameter inUse: This value is set to indicate that the other parameters
     in the sentence are “in-use” by an AIS unit at the time that the AIS unit
     sends this sentence.
     - Parameter inUseChanged: This is the UTC time that the “In-use flag” field
     changed to the indicated state. This field should be `nil` when the
     sentence is sent to an AIS unit.
     - SeeAlso: ``AISChannelInformationSource(sequenceNumber:MMSI:time:)``
     */
    case AISChannelAssignment(
      sequenceNumber: Int?,
      northeastCorner: Position,
      southwestCorner: Position,
      transitionZoneSize: Measurement<UnitLength>,
      channelA: Int,
      channelABandwidth: AIS.ChannelBandwidth,
      channelB: Int,
      channelBBandwidth: AIS.ChannelBandwidth,
      txRxMode: AIS.TransmitReceiveMode,
      powerLevel: AIS.PowerLevel,
      source: AIS.InformationSource?,
      inUse: Bool?,
      inUseChanged: Date?
    )

    /**
     8.3.6 ACK – Acknowledge alarm
    
     Acknowledge device alarm. This sentence is used to acknowledge an alarm
     condition reported by a device.
    
     - Parameter identifier: Unique alarm number (identifier) at alarm source
     */
    case alarmAcknowledgement(identifier: Int)

    /**
     8.3.7 ACS – AIS channel management information source
    
     This sentence is used in conjunction with the ACA sentence. This sentence
     identifies the originator of the information contained in the ACA sentence
     and the date and time the AIS unit received that information.
    
     - Parameter sequenceNumber: This is used to bind the contents of the `ACA`
     and `ACS` sentences together. The `ACS` sentence, when provided by the
     AIS unit, should immediately follow the related `ACA` sentence,
     containing the same sequence number. The AIS unit generating the `ACA`
     and `ACS` sentences, should increment the sequence number each time an
     `ACA`/`ACS` pair is created. After 9 is used the process should begin
     again from 0. Information contained in the `ACS` sentence is not related
     to the information of the `ACA` sentence if the sequence numbers are
     different. When an external device is sending an `ACA` sentence to the
     AIS unit, the sequence number may be `nil` if no `ACS` sentence is being
     sent.
     - Parameter MMSI: MMSI of originator
     - Parameter time: UTC of receipt of channel management information
     - SeeAlso: ``AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    case AISChannelInformationSource(sequenceNumber: Int, MMSI: Int, time: Date)

    /**
     8.3.8 AIR – AIS interrogation request
    
     This sentence supports ITU-R M.1371 Message 10 and 15. It provides an
     external application with the means to initiate requests for specific
     ITU-R M.1371 messages, from distant mobile or base station, AIS units. A
     single sentence can be used to request up to two messages from one AIS unit
     and one message from a second AIS unit, or up to three messages from one
     AIS unit. The message types that can be requested are limited. The complete
     list of messages that may be requested can be found within the Message 15
     description in ITU-R M.1371. Improper requests may be ignored. With Message
     10 always Message 11 is requested.
    
     The external application initiates the interrogation. The external
     application is responsible for assessing the success or failure of the
     interrogation. After receiving this sentence, the AIS unit initiates a
     radio broadcast (on the VHF Data Link) of a Message 10 or 15 –
     interrogation. The success or failure of the interrogation broadcast is
     determined by the application using the combined reception of the
     `ABK`-sentence and `VDM` sentences provided by the AIS unit. After
     receiving this `AIR`-sentence, the AIS unit shall take no more than four
     seconds to broadcast the Message 10 or 15, and the addressed distant
     unit(s) shall take no more than another four seconds to respond – a total
     of eight seconds.
    
     If the requested message type is 11 then a Message 10 is transmitted to
     only one station. The fields of station 2 should be `nil` fields in this
     case.
    
     - Parameter station1: MMSI of interrogated station-1. Identifies the first
     distant AIS unit being interrogated. A single AIR sentence can be used to
     request two message numbers from the first AIS unit.
     - Parameter station1Request1: First message requested from station-1
     - Parameter station1Request2: Second message requested from station-1
     - Parameter station2: MMSI of interrogated station-2. This identifies the
     second distant AIS unit being interrogated. Only one message may be
     requested from the second AIS unit. The MMSI of the second AIS unit may
     be the same MMSI as the first AIS unit.
     - Parameter station2Request: Message requested from station-2
     - Parameter channel: Channel of interrogation. "A", "B", or `nil` if no
     specific channel is being assigned. AIS mobile stations should ignore
     this data field.
     - SeeAlso: ``AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     - SeeAlso: ``VDLMessage(_:channel:)``
     */
    case AISInterrogationRequest(
      station1: Int,
      station1Request1: AIS.MessageRequest,
      station1Request2: AIS.MessageRequest?,
      station2: Int?,
      station2Request: AIS.MessageRequest?,
      channel: AIS.Channel?
    )

    /**
     8.3.9 AKD – Acknowledge detail alarm condition
    
     This sentence provides for acknowledgement of a detailed alarm condition
     reported through `ALA`.
    
     As IEC 61162-1 does not guarantee reliable transport, the designer should
     be very careful about how this sentence is used. Problems can occur either
     when the initial alarm message was lost or when the acknowledgement message
     was lost. A possible solution is to retransmit the alarm message until
     acknowledgement has been received. When acknowledgement has been received,
     an alarm acknowledged should be sent. This acknowledgement should be sent
     on all subsequent acknowledgements. Acknowledgements should be sent on each
     received alarm message after acknowledgement and further on until the alarm
     acknowledgement message has been received.
    
     - Parameter time: Time of acknowledgement
     - Parameter alarm: System indicator of original alarm source and type of
     alarm. Should contain the identical information of the corresponding
     fields from the `ALA` sentence being acknowledged.
     - Parameter instance: Instance number of equipment/unit/item
     - Parameter sender: System indicator of system sending the acknowledgement
     - Parameter senderInstance: Instance of equipment/unit/item sending the
     acknowledgement
     - SeeAlso: ``detailAlarm(time:alarm:instance:condition:acknowledgementState:description:)``
     */
    case detailAlarmAcknowledgement(
      time: Date?,
      alarm: Alarm,
      instance: Int,
      sender: AlarmSystem?,
      senderInstance: Int?
    )

    /**
     8.3.10 ALA – Report detailed alarm condition
    
     This sentence permits the alarm and alarm acknowledge condition of systems
     to be reported. Unlike `ALR` this sentence supports reporting multiple
     system and sub-system alarm conditions.
    
     - Parameter time: Event time of alarm condition change including acknowledgement state change
     - Parameter alarm: System indicator of original alarm source
     - Parameter instance: Instance number of equipment/unit/item
     - Parameter condition: Alarm condition
     - Parameter acknowledgementState: Alarm’s acknowledged state
     - Parameter description: Additional and optional descriptive text/alarm detail condition tag
     - SeeAlso: ``alarmState(changeTime:identifier:thresholdExceeded:acknowledged:description:)``
     - SeeAlso: ``fireDetection(type:time:detector:zone:loop:number:condition:isAcknowledged:description:)``
     - SeeAlso: ``doorStatus(messageType:time:systemType:division1:division2:doorNumber:doorStatus:switchSetting:description:)``
     - SeeAlso: ``hullStress(_:point:isValid:)``
     - SeeAlso: ``waterLevel(messageType:time:systemType:location1:location2:number:alarmCondition:isOverriden:description:)``
     - Note: Dedicated sentences (for example `FIR`, `DOR`, `HSS`, `WAT`) are
     intended for reporting from a dedicated alarm detection system.
     - Note: As IEC 61162-1 does not guarantee reliable transport, the
     designer should be very careful about how this sentence is used.
     Problems can occur either when the initial alarm message was lost or
     when the acknowledgement message was lost. One possible solution (in
     some cases) is to retransmit the alarm message until acknowledgement
     has been received. W hen acknowledgement has been received, an alarm
     acknowledged should be sent. This acknowledgement should be sent on all
     subsequent acknowledgements. Acknowledgements should be sent on each
     received alarm message after acknowledgement and further on until the
     alarm acknowledgement message has been received.
     */
    case detailAlarm(
      time: Date?,
      alarm: Alarm,
      instance: Int,
      condition: AlarmCondition,
      acknowledgementState: AlarmAcknowledgementState,
      description: String?
    )

    /**
     8.3.11 ALR – Set alarm state
    
     Local alarm condition and status. This sentence is used to report an alarm
     condition on a device and its current state of acknowledgement.
    
     - Parameter changeTime: Time of alarm condition change, UTC
     - Parameter identifier: Unique alarm number (identifier) at alarm source
     - Parameter thresholdExceeded: Alarm condition
     - Parameter acknowledged: Alarm’s acknowledge state
     - Parameter description: Alarm’s description text
     */
    case alarmState(
      changeTime: Date,
      identifier: Int,
      thresholdExceeded: Bool,
      acknowledged: Bool,
      description: String?
    )

    /**
     8.3.12 APB – Heading/track controller (autopilot) sentence B
    
     Commonly used by autopilots, this sentence contains navigation receiver
     warning flag status, cross-track-error, waypoint arrival status, initial
     bearing from origin waypoint to the destination, continuous bearing from
     present position to destination and recommended heading to steer to
     destination waypoint for the active navigation leg of the journey.
    
     - Parameter LORANC_blinkSNRFlag: LORAN-C blink or SNR warning
     - Parameter LORANC_cycleLockWarningFlag: LORAN-C cycle lock warning flag
     - Parameter crossTrackError: Magnitude and direction of XTE (left =
     negative)
     - Parameter arrivalCircleEntered: Arrival circle entered, or not passed
     - Parameter perpendicularPassed: Perpendicular passed at waypoint, or not
     entered
     - Parameter bearingOriginToDest: Bearing origin to destination, M/T
     - Parameter destinationID: Destination waypoint ID
     - Parameter bearingPresentPosToDest: Bearing, present position to
     destination, magnetic or true
     - Parameter headingToDest: Heading to steer to destination waypoint,
     magnetic or true
     - Parameter mode: Mode indicator
     */
    case autopilotSentenceB(
      LORANC_blinkSNRFlag: Bool,
      LORANC_cycleLockWarningFlag: Bool,
      crossTrackError: Measurement<UnitLength>,
      arrivalCircleEntered: Bool,
      perpendicularPassed: Bool,
      bearingOriginToDest: Bearing,
      destinationID: String,
      bearingPresentPosToDest: Bearing,
      headingToDest: Bearing,
      mode: Navigation.Mode
    )

    /**
     8.3.13 BBM – AIS broadcast binary message
    
     This sentence supports generation of ITU-R M.1371 binary Messages 8 and 14.
     This provides the application with a means to broadcast data, as defined by
     the application only. Data is defined by the application only – not the
     AIS. This message offers great flexibility for implementing system
     functions that use the AIS unit as a digital broadcast device. After
     receiving this sentence, via the IEC 61162-2 interface, the AIS unit
     initiates a VHF broadcast of either Message 8 or 14 within 4 s. (See the
     `ABK` sentence for acknowledgement of the `BBM`.)
    
     - Parameter sequentialIdentifier: Sequential message identifier, 0 to 9.
     The sequential message identifier provides a message identification
     number from 0 to 9 that is sequentially assigned and is incremented for
     each new multi-sentence message. The count resets to 0 after 9 is used.
     For a message requiring multiple sentences, each sentence of the message
     contains the same sequential message identification number. It is used to
     identify the sentences containing portions of the same message. This
     allows for the possibility that other sentences might be interleaved with
     the message sentences that, taken collectively, contain a single message.
     This value is used by the `ABK` sentence to acknowledge a specific `BBM`
     sentence.
     - Parameter channel: The AIS channel that should be used for the broadcast.
     - Parameter messageID: ITU-R M.1371 Message ID (``AIS/MessageID/broadcastBinary`` or ``AIS/MessageID/broadcastSafety``).
     - Parameter data: This is the content of the “binary data” parameter for
     ITU-R M.1371 Message 8, or the “Safety related text” parameter for
     Message 14.
     - SeeAlso: ``AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     */
    case AISBroadcastBinaryMessage(
      sequentialIdentifier: Int,
      channel: AIS.BroadcastChannel?,
      messageID: AIS.MessageID?,
      data: Data
    )

    /**
     8.3.14 BEC – Bearing and distance to waypoint – Dead reckoning
    
     Time (UTC) and distance and bearing to, and location of, a specified
     waypoint from the dead-reckoned present position.
    
     - Parameter observationTime: UTC of observation
     - Parameter waypointPosition: Waypoint position
     - Parameter bearingTrue: Bearing, degrees true
     - Parameter bearingMagnetic: Bearing, degrees magnetic
     - Parameter distance: Distance, nautical miles
     - Parameter waypointID: Waypoint ID
     - SeeAlso: ``bearingDistanceToWaypointGC(observationTime:position:bearingTrue:bearingMagnetic:distance:waypointID:mode:)``
     - SeeAlso: ``bearingDistanceToWaypointRL(observationTime:position:bearingTrue:bearingMagnetic:distance:waypointID:mode:)``
     */
    case bearingDistanceToWaypointDR(
      observationTime: Date,
      waypointPosition: Position,
      bearingTrue: Bearing,
      bearingMagnetic: Bearing,
      distance: Measurement<UnitLength>,
      waypointID: String
    )

    /**
     8.3.15 BOD – Bearing origin to destination
    
     Bearing angle of the line, calculated at the origin waypoint, extending to
     the destination waypoint from the origin waypoint for the active navigation
     leg of the journey.
    
     - Parameter bearingTrue: Bearing, degrees true
     - Parameter bearingMagnetic: Bearing, degrees magnetic
     - Parameter destinationWaypointID: Destination waypoint ID
     - Parameter originWaypointID: Origin waypoint ID
     */
    case bearingOriginToDest(
      bearingTrue: Bearing,
      bearingMagnetic: Bearing,
      destinationWaypointID: String,
      originWaypointID: String
    )

    /**
     8.3.16 BWC – Bearing and distance to waypoint – Great circle
    
     Time (UTC) and distance and bearing to, and location of, a specified
     waypoint from present position. `BWC` data is calculated along the great
     circle path from present position rather than along the rhumb line.
    
     - Parameter observationTime: UTC of observation
     - Parameter waypointPosition: Waypoint position
     - Parameter bearingTrue: Bearing, degrees true
     - Parameter bearingMagnetic: Bearing, degrees magnetic
     - Parameter distance: Distance, nautical miles
     - Parameter waypointID: Waypoint ID
     - SeeAlso: ``bearingDistanceToWaypointDR(observationTime:waypointPosition:bearingTrue:bearingMagnetic:distance:waypointID:)``
     - SeeAlso: ``bearingDistanceToWaypointRL(observationTime:position:bearingTrue:bearingMagnetic:distance:waypointID:mode:)``
     */
    case bearingDistanceToWaypointGC(
      observationTime: Date,
      position: Position,
      bearingTrue: Bearing,
      bearingMagnetic: Bearing,
      distance: Measurement<UnitLength>,
      waypointID: String,
      mode: Navigation.Mode
    )

    /**
     8.3.16 BWR – Bearing and distance to waypoint – Rhumb line
    
     Time (UTC) and distance and bearing to, and location of, a specified
     waypoint from present position. `BWR` data is calculated along the great
     circle path from present position rather than along the rhumb line.
    
     - Parameter observationTime: UTC of observation
     - Parameter waypointPosition: Waypoint position
     - Parameter bearingTrue: Bearing, degrees true
     - Parameter bearingMagnetic: Bearing, degrees magnetic
     - Parameter distance: Distance, nautical miles
     - Parameter waypointID: Waypoint ID
     - SeeAlso: ``bearingDistanceToWaypointDR(observationTime:waypointPosition:bearingTrue:bearingMagnetic:distance:waypointID:)``
     - SeeAlso: ``bearingDistanceToWaypointGC(observationTime:position:bearingTrue:bearingMagnetic:distance:waypointID:mode:)``
     */
    case bearingDistanceToWaypointRL(
      observationTime: Date,
      position: Position,
      bearingTrue: Bearing,
      bearingMagnetic: Bearing,
      distance: Measurement<UnitLength>,
      waypointID: String,
      mode: Navigation.Mode
    )

    /**
     8.3.18 BWW – Bearing waypoint to waypoint
    
     Bearing angle of the line, between the TO and the FROM waypoints,
     calculated at the FROM waypoint for any two arbitrary waypoints.
    
     - Parameter bearingTrue: Bearing, degrees
     - Parameter bearingMagnetic: Bearing, degrees magnetic
     - Parameter toWaypointID: TO waypoint ID
     - Parameter fromWaypointID: FROM waypoint ID
     */
    case bearingWaypointToWaypoint(
      bearingTrue: Bearing,
      bearingMagnetic: Bearing,
      toWaypointID: String,
      fromWaypointID: String
    )

    /**
     8.3.19 CBR – Configure broadcast rates for AIS AtoN station message command
    
     This sentence configures slots and transmission intervals that will be used
     to broadcast AIS Class A message ``AIS/MessageID/multiSlotBinary``. For
     Class A only Message ID 26 is allowed. Only the “slot interval” is used
     to define the SOTDMA reporting interval. If “slot interval, channel A”
     is defined only, the Class A transmits message 26 only on channel A
     with the defined reporting interval. If “slot interval, channel BA” is
     defined only, the Class A transmits message 26 only on channel B with
     the defined reporting interval. If both slot intervals are defined they
     have to be identical, and message 26 is transmitted alternating on
     channel A and B.
    
     This sentence can be queried. The query response may contain one or
     more sentences and will continue until the transfer of all current
     schedule information is complete.
    
     - Parameter MMSI: This is a MMSI previously defined for the AIS navaid
     station.
     - Parameter message: The number of the message being scheduled
     - Parameter index: Message ID Index is used to distinguish multiple
     occurrences of the same MMSI and Message ID combination. Valid range is
     0 to 7.
     - Parameter channelA: The slot configured for channel A
     - Parameter scheduleType: FATDMA or RATDMA/CSTDMA setup
     - Parameter channelB: The slot configured for channel B
     - Parameter type: Sentence status flag
     */
    case navaidMessageBroadcastRates(
      MMSI: Int,
      message: Navaid.MessageID,
      index: Int,
      channelA: Navaid.SlotConfiguration,
      scheduleType: Navaid.Schedule,
      channelB: Navaid.SlotConfiguration?,
      type: SentenceType
    )

    /**
     8.3.20 CUR – Water current layer – Multi-layer water current data
    
     - Parameter isValid: Validity of the data
     - Parameter setNumber: Data set number, 0 to 9. The data set number is used
     to identify multiple sets of current data produced in one measurement
     instance. Each measurement instance may result in more than one sentence
     containing current data measurements at different layers, all with the
     same data set number. This is used to avoid the data measured in another
     instance to be accepted as one set of data.
     - Parameter layer: The layer number identifies which layer the current data
     measurements were made from. The number of layers that can be measured
     varies by device. The typical number is between 3 and 32, though many
     more are possible.
     - Parameter depth: Current depth in metres
     - Parameter direction: Current direction in degrees
     - Parameter speed: Current speed in knots
     - Parameter referenceDepth: Reference layer depth in metres. The current of
     each layer is measured according to this reference layer, when the speed
     reference field is set to “water track”, or the depth is too deep for
     bottom track.
     - Parameter heading: Heading
     - Parameter speedReference: Speed reference
     */
    case currentWaterLayer(
      isValid: Bool,
      setNumber: Int,
      layer: Int,
      depth: Measurement<UnitLength>,
      direction: Bearing,
      speed: Measurement<UnitSpeed>,
      referenceDepth: Measurement<UnitLength>,
      heading: Bearing,
      speedReference: WaterSensor.SpeedReference
    )

    /**
     8.3.21 DBT – Depth below transducer
    
     Water depth referenced to the transducer.
    
     - Parameter depths: Water depths measured in different units (feet, meters,
     fathoms).
     */
    case depthBelowTransducer(_ depths: [Measurement<UnitLength>])

    /**
     8.3.22 DDC – Display dimming control
    
     The `DDC` sentence provides controls for equipment display dimming presets
     and a display brightness percentage.
    
     - Parameter preset: The display dimming preset field contains an indicator
     that may be associated with a preset dimmed level on an electronic
     device. Actual display brightness levels for the display dimming preset
     indicators above are dependant upon the capabilities provided by the
     manufacturer of the equipment. Proper use of this field would be as
     follows. A device provides the operator or user with the ability to set a
     brightness level to be associated with day, dusk night, etc. Upon receipt
     of the `DDC` sentence, the device would switch its display brightness to
     the preset value the operator had determined for the corresponding
     indicator value. If the equipment had no brightness or dimming preset
     capability this field would be ignored.
     - Parameter brightness: Brightness percentage 00 to 99. The brightness
     percentage field contains a value from zero to ninety nine. The value
     zero indicates that the display’s brightness should be set to its most
     dimmed level, as determined by the capabilities of the equipment. The
     value ninety nine indicates that the display brightness should be set to
     the brightest level, as determined by the capabilities of the equipment.
     Values between 0 and 99 correspond to some percentage of brightness, as
     determined by the equipment receiving this sentence.
     - Parameter colorPalette: The colour palette preset field contains an
     indicator that may be associated with a preset dimmed level on an
     electronic device.
     - Parameter status: This field is used to indicate a sentence that is a
     status report of current settings or a configuration command changing
     settings.
     */
    case displayDimmingControl(
      preset: DimmingPreset?,
      brightness: Int?,
      colorPalette: DimmingPreset?,
      status: SentenceType
    )

    /**
     8.3.23 DOR – Door status detection
    
     This sentence indicates the status of watertight doors, fire doors or other
     hull openings / doors.
    
     - Parameter messageType: Message Type
     - Parameter time: Time when this status/message was valid
     - Parameter systemType: Type of door monitoring system
     - Parameter division1: First division indicator where door is located
     - Parameter division2: Second division indicator where the door is located
     - Parameter doorNumber: Door number or door open count. When `messageType`
     is ``Doors/MessageType/event`` this field identifies the door. When
     `messageType` is ``Doors/MessageType/section`` this field contains the
     number of doors that are open or faulty. When `messageType` is F this
     field is `nil`.
     - Parameter doorStatus: Door status. When `messageType` is
     ``Doors/MessageType/section`` or ``Doors/MessageType/fault`` this field
     should be `nil`.
     - Parameter switchSetting: Water tight door switch setting
     - Parameter description: Descriptive text/door tag. If a door allocation
     identifier is string type, it is possible to use this field instead of
     the above door allocation fields. The maximum number of characters will
     be limited by the maximum sentence length and the length of other fields.
     */
    case doorStatus(
      messageType: Doors.MessageType,
      time: Date?,
      systemType: Doors.SystemType,
      division1: String?,
      division2: String?,
      doorNumber: Int?,
      doorStatus: Doors.Status?,
      switchSetting: Doors.SwitchSetting?,
      description: String?
    )

    /**
     8.3.24 DPT – Depth
    
     Water depth relative to the transducer and offset of the measuring
     transducer. Positive offset numbers provide the distance from the
     transducer to the waterline. Negative offset numbers provide the distance
     from the transducer to the part of the keel of interest.
    
     - Parameter depth: Water depth relative to the transducer, in metres
     - Parameter offset: Offset from transducer, in metres. Positive = distance
     from transducer to water line; negative = distance from transducer to
     keel. For IEC applications, the offset should always be applied so as to
     provide depth relative to the keel.
     - Parameter maxRange: Maximum range scale in use
     */
    case depth(
      _ depth: Measurement<UnitLength>,
      offset: Measurement<UnitLength>,
      maxRange: Measurement<UnitLength>
    )

    /**
     8.3.25 DSC – Digital selective calling information
    
     This sentence is used to receive a call from or provide data to a
     radiotelephone using digital selective calling in accordance with
     ITU-R M.493-16.
    
     - Parameter format: Format specifier
     - Parameter address: Maritime Mobile Service Identifier (MMSI) for the
     station to be called or the MMSI of the calling station in a received
     call. `nil` if `format` is ``DSC/FormatSpecifier/geographic``.
     - Parameter area: The geographic area, if `format` is
     ``DSC/FormatSpecifier/geographic``. `nil` otherwise.
     - Parameter category: Category
     - Parameter message1_1: For distress calls, this contains the nature of
     distress, as coded in ITU-R M.493-16. It can be decoded using the
     ``DSC/DistressNature`` enum. For other calls, this contains the
     first telecommand, also coded as specified in ITU-R M.493-16. It can be
     decoded using the ``DSC/Telecommand1`` enum.
     - Parameter message1_2: For distress calls, this contains the type of
     communication desired, as coded in ITU-R M.493-16. It can be decoded
     using the ``DSC/DistressCommunicationDesired`` enum. For other calls,
     this contains the second telecommand, also coded as specified in
     ITU-R M.493-16. It can be decoded using the ``DSC/Telecommand2`` enum.
     - Parameter message2: For distress calls, this contains the distress
     coordinates, coded as specified in ITU-R M.493-16. It can be decoded
     using the ``DSC/distressCoordinates(from:)`` function. For other calls,
     this contains two channel or frequency message elements, coded as specified in
     ITU-R M.493-16. It can be decoded using the ``DSC/FrequencyChannel``
     enum.
     - Parameter message3: For distress calls, this contains the UTC time during
     which the distress position provided in `message2` was valid. It can be
     decoded using the ``DSC/time(from:referenceDate:)`` function. For other
     calls, this contains the network telelphone number. It can be decoded
     using the ``DSC/networkNumber(from:)`` function.
     - Parameter distressMMSI: MMSI of ship in distress. For distress
     acknowledgement, distress relay and distress relay acknowledgement calls
     only, `nil` otherwise.
     - Parameter distressMMSINature: Nature of distress. For distress
     acknowledgement, distress relay and distress relay acknowledgement calls
     only, `nil` otherwise.
     - Parameter acknowledgement: Distress acknowledgement type.
     - Parameter expansion: Expansion indicator. When `true` this sentence is
     followed by the `DSC` expansion sentence `DSE`, without intervening
     sentences, as the next transmitted or received sentence.
     - SeeAlso: ``DSE(type:MMSI:data:)``
     */
    case DSC(
      format: DSC.FormatSpecifier,
      MMSI: Int?,
      area: GeoArea?,
      category: DSC.Category,
      message1_1: String?,
      message1_2: String?,
      message2: String?,
      message3: String?,
      distressMMSI: Int?,
      distressMMSINature: DSC.DistressNature?,
      acknowledgement: DSC.Acknowledgement?,
      expansion: Bool
    )

    /**
     8.3.26 DSE – Expanded digital selective calling
    
     This sentence immediately follows, without intervening sentences or
     characters, `DSC`, `DSI`, or `DSR` when the DSC `expansion` field in
     these sentences is set to `true`. It is used to provide data to or
     receive DSC expansion data from a radiotelephone using digital selective
     calling in accordance with ITU-R M.821.
    
     - Parameter type: Query/reply flag
     - Parameter MMSI: Vessel MMSI. Identical to the address field in the
     associated `DSC`, `DSI`, or `DSR` sentence.
     - Parameter data: Data sets
     - SeeAlso: ``DSC(format:MMSI:area:category:message1_1:message1_2:message2:message3:distressMMSI:distressMMSINature:acknowledgement:expansion:)``
     */
    case DSE(type: DSE.MessageType, MMSI: Int, data: [SwiftDSE.Message])

    /**
     8.3.27 DTM – Datum reference
    
     Local geodetic datum and datum offsets from a reference datum. This
     sentence is used to define the datum to which a position location, and
     geographic locations in subsequent sentences, are referenced. Latitude,
     longitude and altitude offsets from the reference datum, and the selection
     of the reference datum, are also provided.
    
     Cautionary notes: the datum sentence should be transmitted immediately
     prior to every positional sentence (e.g. `GLL`, `BWC`, `WPL`) which is
     referenced to a datum other than WGS84, the datum recommended by IMO.
    
     `latitudeOffset` and `longitudeOffset` are positive numbers;
     `altitudeOffset` may be negative. Offsets change with position: position
     in the local datum is offset from the position in the reference datum in
     the directions indicated:
    
     P(local datum) = P(ref datum) + offset
    
     When `localDatum` is ``Datum/userDefined(subdivision:)``, these fields may
     not be `nil`, and should contain the manually entered or user defined
     offsets.
    
     Users should be aware that chart transformations based on IHO S60
     parameters may result in significant positional errors when applied to
     chart data.
    
     - Parameter localDatum: Local datum
     - Parameter latitudeOffset: Latitude offset, minutes, N/S
     - Parameter longitudeOffset: Longitude offset, minutes, E/W
     - Parameter altitudeOffset: Altitude offset, m
     - Parameter referenceDatum: Reference datum
     - SeeAlso: ``geoPosition(_:time:isValid:mode:)``
     - SeeAlso: ``bearingDistanceToWaypointGC(observationTime:position:bearingTrue:bearingMagnetic:distance:waypointID:mode:)``
     - SeeAlso: ``waypointLocation(_:identifier:)``
     */
    case datumReference(
      localDatum: Datum,
      latitudeOffset: Measurement<UnitAngle>?,
      longitudeOffset: Measurement<UnitAngle>?,
      altitudeOffset: Measurement<UnitLength>?,
      referenceDatum: Datum
    )

    /**
     8.3.28 ETL – Engine telegraph operation status
    
     This sentence indicates engine telegraph position including operating
     location and sub-telegraph indicator.
    
     - Parameter time: Event time of condition change. This may be a `nil` field.
     - Parameter type: Message type
     - Parameter position: Position indicator of engine telegraph
     - Parameter subPosition: Position indication of sub telegraph
     - Parameter location: Operating location indicator
     - Parameter number: Number of engine or propeller shaft controlled by the
     system. This is numbered from centre-line. This field is single
     character: 0 = single or on centre-line, Odd = starboard, Even = port
     */
    case engineTelegraph(
      time: Date?,
      type: EngineTelegraph.MessageType,
      position: EngineTelegraph.Position,
      subPosition: EngineTelegraph.SubPosition,
      location: Propulsion.Location?,
      number: Int
    )

    /**
     8.3.29 EVE – General event message
    
     This sentence is used to transmit events (e.g. actions by the crew on the
     bridge) with a time stamp.
    
     - Parameter time: Event time
     - Parameter tag: Tag code used for identification of source of event
     - Parameter description: Event description
     */
    case event(time: Date?, tag: String?, description: String)

    /**
     8.3.30 FIR – Fire detection
    
     This sentence indicates fire detection status with data on the specific
     location.
    
     For a `type` of ``Fire/MessageType/section``, the number of faulty and
     activated condition reported as `number`. The section may be a whole
     section (`zone` and/or `loop` are `nil`) or a sub-section. This status is
     normally transmitted at regular intervals. In this case, `condition` and
     `isAcknowledged` are `nil`.
    
     For a type of ``Fire/MessageType/event``, the individual alarm number is
     reported as `number`. `zone` and `loop` are typically provided, and
     `condition` and `isAcknowledged` are not `nil`.
    
     For types of ``Fire/MessageType/disabled``, the individual alarm number is
     reported as `number`, and `isAcknowledged` is `nil`.
    
     For types of ``Fire/MessageType/fault``, the individual alarm number is
     reported as `number`, and `condition` and `isAcknowledged` are `nil`.
    
     - Parameter type: Message Type
     - Parameter time: Time of condition change or acknowledgement
     - Parameter detector: Type of fire detection system
     - Parameter zone: First division indicator: Number / letter of zone. This
     can also be a control and monitoring system main unit identifier, for
     example fire central number/letter.
     - Parameter loop: Second division indicator: Loop number. This can also be
     another control and monitoring sub-system identifier, for example
     sub-central number.
     - Parameter number: Fire detector number or activation detection count
     - Parameter condition: Condition
     - Parameter isAcknowledged: Alarm’s acknowledgement state
     - Parameter description: Descriptive text/sensor location tag. If a sensor
     location identifier is string type, it is possible to use this field
     instead of above sensor allocation fields.
     */
    case fireDetection(
      type: Fire.MessageType,
      time: Date?,
      detector: Fire.DetectorType,
      zone: String?,
      loop: Int?,
      number: Int?,
      condition: Fire.DetectorCondition?,
      isAcknowledged: Bool?,
      description: String?
    )

    /**
     8.3.31 FSI – Frequency set information
    
     This sentence is used to set frequency, mode of operation and transmitter
     power level of a radiotelephone; to read out frequencies, mode and power
     and to acknowledge setting commands. This is a command sentence.
    
     For paired frequencies, only `transmit` needs to be included; `nil` for
     `receive`. For receive frequencies only, `transmit` should be `nil`.
    
     - Parameter transmit: Transmitting frequency
     - Parameter receive: Receiving frequency
     - Parameter mode: Mode of operation, `nil` for no information
     - Parameter powerLevel: Power level, 0 = standby, 1 = lowest, 9 = highest
     - Parameter type: Sentence status flag
     */
    case frequencySetInfo(
      transmit: Comm.Frequency?,
      receive: Comm.Frequency?,
      mode: Comm.OperationMode?,
      powerLevel: Int?,
      type: SentenceType
    )

    /**
     8.3.32 GBS – GNSS satellite fault detection
    
     This sentence is used to support Receiver Autonomous Integrity Monitoring
     (RAIM). Given that a GNSS receiver is tracking enough satellites to perform
     an integrity check of the position solution a sentence is needed to report
     the output of this process to other systems to advise the system user. With
     the RAIM in the GNSS receiver, the receiver can isolate faults to
     individual satellites and not use them in its position and velocity
     calculations. Also, the GNSS receiver can still track the satellite and
     easily judge when it is back within tolerance. This sentence shall be used
     for reporting this RAIM information. To perform this integrity function,
     the GNSS receiver should have at least two observables in addition to the
     minimum required for navigation. Normally these observables take the form
     of additional redundant satellites.
    
     If only GPS, GLONASS, etc. is used for the reported position solution the
     talker ID is GP, GL, etc. and the errors pertain to the individual system.
     If satellites from multiple systems are used to obtain the reported
     position solution the talker ID is GN and the errors pertain to the
     combined solution.
    
     - Parameter time: UTC time of the `GGA` or `GNS` fix associated with
     this sentence
     - Parameter latitudeError: Expected error in latitude, in metres due to
     bias, with noise = 0.
     - Parameter longitudeError: Expected error in longitude, in metres due to
     bias, with noise = 0.
     - Parameter altitudeError: Expected error in altitude, in metres due to
     bias, with noise = 0.
     - Parameter failedSatellite: ID of most likely failed satellite
     - Parameter missProbability: Probability of missed detection for most
     likely failed satellite
     - Parameter biasEstimate: Estimate of bias on most likely failed satellite
     (in metres)
     - Parameter biasEstimateStddev: Standard deviation of bias estimate
     - SeeAlso: ``GPSFix(_:time:quality:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:)``
     - SeeAlso: ``GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     */
    case GNSSFaultDetection(
      time: Date,
      latitudeError: Measurement<UnitLength>,
      longitudeError: Measurement<UnitLength>,
      altitudeError: Measurement<UnitLength>,
      failedSatellite: GNSS.SatelliteID,
      missProbability: Double,
      biasEstimate: Measurement<UnitLength>,
      biasEstimateStddev: Measurement<UnitLength>
    )

    /**
     8.3.33 GEN – Generic binary information
    
     This sentence provides a means of transmitting generic binary information
     (e.g. lamp display status). The sentence is designed for efficient use of
     the bandwidth. In general, the proper decoding and interpretation of binary
     data will require access to information developed and maintained outside of
     this standard. This standard contains information that describes how the
     data should be coded, decoded, and structured. The specific meaning of the
     binary data is obtained outwith this standard.
    
     Data too large for a single sentence is represented by consecutive `GEN`
     sentences, where `index` increments by the number of groups in the previous
     sentence. For example, 20 bytes of generic data (encoded in 10 groups)
     must be represented as 2 sentences, one with 8 groups, and one with 2
     groups. `index` will be 0 in the first sentence, and 8 in the second
     sentence.
    
     Because `GEN` sentences have no "total size" field, there is no direct
     way of knowing when a message split across group of `GEN` sentences
     has completed transmitting. Because of this, there are only two ways
     to receive a `genericBinary` message:
    
     * when a subsequent message is sent that resets the running byte
     counter, the _previous_ `genericBinary` message will be returned by
     ``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)``;
     * by calling ``SwiftNMEA/SwiftNMEA/flush(talker:format:includeIncomplete:)``.
    
     - Parameter time: Time stamp
     - Parameter data: Generic data
     */
    case genericBinary(time: Date?, data: Data)

    /**
     8.3.34 GFA – GNSS fix accuracy and integrity
    
     This sentence is used to report the results of the data quality and
     integrity check associated with a position solution to other systems and to
     advise the system user. If only a single constellation (GPS, GLONASS,
     GALILEO, etc.) is used for the reported position solution, the talker ID is
     ``Talker/GPS``, ``Talker/GLONASS``, ``Talker/galileo``, etc. and the data
     pertain to the individual system. If satellites from multiple systems are
     used to obtain the reported position solution, the talker ID is
     ``Talker/GNSS`` and the parameters pertain to the combined solution. This
     sentence provides the quality data of the position fix and should be
     associated with the `GNS` sentence.
    
     - Parameter time: UTC time of GNS fix associated with this sentence
     - Parameter HPL: Horizontal protection level (m)
     - Parameter VPL: Vertical protection level (m)
     - Parameter semimajorStddev: Standard deviation of semi-major axis of error
     ellipse (m)
     - Parameter semiminorStddev: Standard deviation of semi-minor axis of error
     ellipse (m)
     - Parameter semimajorErrorOrientation: Orientation of semi-major axis of
     error ellipse (°T)
     - Parameter altitudeStddev: Standard deviation of altitude (m)
     - Parameter selectedAccuracy: Selected accuracy level (m). The selected
     accuracy level and the associated integrity requirements (alert limit,
     integrity risk limit, continuity, time-to-alarm) should be in accordance
     with Appendix 2 of IMO Res. A. 915(22).
     - Parameter integrity: Integrity status of relevant integrity sources
     - SeeAlso: ``GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     */
    case GNSSAccuracyIntegrity(
      time: Date,
      HPL: Measurement<UnitLength>,
      VPL: Measurement<UnitLength>,
      semimajorStddev: Measurement<UnitLength>,
      semiminorStddev: Measurement<UnitLength>,
      semimajorErrorOrientation: Bearing,
      altitudeStddev: Measurement<UnitLength>,
      selectedAccuracy: Measurement<UnitLength>,
      integrity: [GNSS.IntegritySource: GNSS.IntegrityStatus]
    )

    /**
     8.3.35 GGA – Global positioning system (GPS) fix data
    
     Time, position and fix-related data for a GPS receiver.
    
     - Parameter position: GPS fix position
     - Parameter time: UTC of position
     - Parameter quality: GPS quality indicator
     - Parameter numSatellites: Number of satellites in use, 0–12, may be
     different from the number in view
     - Parameter HDOP: Horizontal dilution of precision
     - Parameter geoidalSeparation: Geoidal separation. The difference between
     the WGS-84 earth ellipsoid surface and mean sea level (geoid) surface,
     negative = mean sea level surface below the WGS-84 ellipsoid surface.
     - Parameter DGPSAge: Age of differential GPS data. Time in seconds since
     last SC104 type 1 or 9 update, `nil` field when DGPS is not used.
     - Parameter DGPSReferenceStationID: Differential reference station ID, 0–1023
     */
    case GPSFix(
      _ position: Position,
      time: Date,
      quality: GNSS.GPSQuality,
      numSatellites: Int,
      HDOP: Double,
      geoidalSeparation: Measurement<UnitLength>,
      DGPSAge: Measurement<UnitDuration>?,
      DGPSReferenceStationID: Int?
    )

    /**
     8.3.36 GLL – Geographic position – Latitude/longitude
    
     Latitude and longitude of vessel position, time of position fix and status.
    
     - Parameter position: Fix position. Altitude will be `nil`.
     - Parameter time: UTC of position
     - Parameter isValid: Status of data (valid or invalid)
     - Parameter mode: Mode indicator. The mode indicator field supplements the
     `isValid` field. `isValid` should be false for all values of `mode`
     except for ``Navigation/Mode/autonomous`` and ``Navigation/Mode/differential``.
     */
    case geoPosition(_ position: Position, time: Date, isValid: Bool, mode: Navigation.Mode)

    /**
     8.3.37 GNS – GNSS fix data
    
     Fix data for single or combined satellite navigation systems (GNSS). This
     sentence provides fix data for GPS, GLONASS, possible future satellite
     systems and systems combining these. This sentence could be used with the
     talker identification of ``Talker/GPS`` for GPS, ``Talker/GLONASS`` for
     GLONASS, ``Talker/galileo`` for Galileo, ``Talker/GNSS`` for GNSS combined
     systems, as well as future identifiers. Some fields may be `nil` for
     certain applications, as described below. If a GNSS receiver is capable
     simultaneously of producing a position using combined satellite systems, as
     well as a position using only one of the satellite systems, then separate
     ``Talker/GPS``, ``Talker/GLONASS``, etc. sentences may be used to report
     the data calculated from the individual systems.
    
     If a GNSS receiver is set up to use more than one satellite system, but for
     some reason one or more of the systems are not available, then it may
     continue to report the positions using ``Talker/GNSS``, and use the `mode`
     to show which satellite systems are being used.
    
     When the talker is ``Talker/GNSS`` and more than one of the satellite
     systems are used in differential mode, then the `DGPSAge` and
     `DGPSReferenceStationID` fields should be `nil`. In this case, the
     “Age of differential data” and “Differential reference station ID” data
     should be provided in following `GNS` sentences with talker IDs of
     ``Talker/GPS``, ``Talker/GLONASS``, etc. These following `GNS` messages
     should have the `position`, `geoidalSeparation`, `mode`, and `HDOP` fields
     be `nil`. This indicates to the listener that the field is supporting a
     previous `GNS` sentence with the same time tag. The `numSatellites` field
     may be used in these following sentences to denote the number of satellites
     used from that satellite system.
    
     ## Age of Differential Data
    
     For GPS Differential Data: This value is the average age of the most recent
     differential corrections in use. When only RTCM SC104 Type 1 corrections
     are used, the age is that of the most recent Type 1 correction. When
     RTCM SC104 Type 9 corrections are used solely, or in combination with
     Type 1 corrections, the age is the average of the most recent corrections
     for the satellites used. `nil` when Differential GPS is not used.
    
     For GLONASS Differential Data: This value is the average age of the most
     recent differential corrections in use. When only RTCM SC104 Type 31
     corrections are used, the age is that of the most recent Type 31
     correction. When RTCM SC104 Type 34 corrections are used solely, or in
     combination with Type 31 corrections, the age is the average of the most
     recent corrections for the satellites used. `nil` when differential GLONASS
     is not used.
    
     For Galileo Differential Data: This value is the average age of the most
     recent differential corrections in use. When only RTCM SC104 Type 41
     corrections are used, the age is that of the most recent Type 41
     correction. When RTCM SC104 Type 42 corrections are used solely, or in
     combination with Type 41 corrections, the age is the average of the most
     recent corrections for the satellites used. `nil` when differential Galileo
     is not used.
    
     - Parameter position: Fix position, including altitude
     - Parameter time: UTC of position
     - Parameter mode: Mode indicator for each GNSS system
     - Parameter numSatellites: Total number of satellites in use
     - Parameter HDOP: Horizontal dilution of precision. HDOP calculated using
     all the satellites (GPS, GLONASS, Galileo and any future satellites) used
     in computing the solution reported in each `GNS` sentence.
     - Parameter geoidalSeparation: Geoidal separation, m. The difference
     between the earth ellipsoid surface and mean-sea-level (geoid) surface
     defined by the reference datum used in the position solution,
     negative = mean-sea-level surface below ellipsoid. The reference datum
     may be specified in the `DTM` sentence.
     - Parameter DGPSAge: Age of differential data (see note)
     - Parameter DGPSReferenceStationID: Differential reference station ID
     - Parameter status: Navigational status indicator. The navigational status
     indicator is according to IEC 61108 requirements on ‘Navigational (or
     Failure) warnings and status indications’.
     - SeeAlso: ``datumReference(localDatum:latitudeOffset:longitudeOffset:altitudeOffset:referenceDatum:)``
     */
    case GNSSFix(
      _ position: Position?,
      time: Date,
      mode: [GNSS.System: Navigation.Mode]?,
      numSatellites: Int,
      HDOP: Double?,
      geoidalSeparation: Measurement<UnitLength>?,
      DGPSAge: Measurement<UnitDuration>?,
      DGPSReferenceStationID: Int?,
      status: GNSS.IntegrityStatus
    )

    /**
     8.3.38 GRS – GNSS range residuals
    
     This sentence is used to support Receiver Autonomous Integrity Monitoring
     (RAIM). Range residuals can be computed in two ways for this process. The
     basic measurement integration cycle of most navigation filters generates a
     set of residuals and uses these to update the position state of the
     receiver. These residuals can be reported with `GRS`, but because of the
     fact that these were used to generate the navigation solution they should
     be recomputed using the new solution in order to reflect the residuals for
     the position solution in the `GGA` or `GNS` sentence. The `recomputed
     field should indicate which computation method was used. An integrity
     process that uses these range residuals would also require `GGA` or `GNS`,
     the `GSA`, and the `GSV` sentences to be sent.
    
     If only GPS, GLONASS, Galileo etc. is used for the reported position
     solution the talker ID is ``Talker/GPS``, ``Talker/GLONASS``,
     ``Talker/galileo``, etc. and the range residuals pertain to the individual
     system. If GPS, GLONASS, Galileo, etc. are combined to obtain the position
     solution multiple `GRS` sentences are produced, one with the GPS
     satellites, another with the GLONASS satellites, another with Galileo
     satellites, etc. each of these `GRS` sentences shall have talker ID
     ``Talker/GNSS``, to indicate that the satellites are used in a combined
     solution. It is important to distinguish the residuals from those that
     would be produced by a GPS-only, GLONASS-only, Galileo-only, etc. position
     solution. In general the residuals for a combined solution will be
     different from the residual for a GPS-only, GLONASS-only, Galileo-only,
     etc. solution.
    
     - Parameter residuals: Range residuals for satellites used in the
     navigation. If the range residual exceeds ±99,9 m, then the decimal part
     is dropped, resulting in an integer (–103,7 becomes –103). The maximum
     value for this field is ±999.
     - Parameter time: UTC time of the `GGA` or `GNS` fix associated with this
     sentence
     - Parameter recomputed: If `false`, residuals were used to calculate the
     position given in the matching `GGA` or `GNS` sentence. If `true`,
     residuals were re-computed after the `GGA` or `GNS` position was computed.
     - SeeAlso: ``geoPosition(_:time:isValid:mode:)``
     - SeeAlso: ``GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     - SeeAlso: ``GNSS_DOP(PDOP:HDOP:VDOP:auto3D:solution:ids:)``
     - SeeAlso: ``GNSSSatellitesInView(_:total:)``
     */
    case GNSSRangeResiduals(
      _ residuals: [GNSS.SatelliteID: Measurement<UnitLength>],
      time: Date,
      recomputed: Bool
    )

    /**
     8.3.39 GSA – GNSS DOP and active satellites
    
     GNSS receiver operating mode, satellites used in the navigation solution
     reported by the `GGA` or `GNS` sentences, and DOP values. If only GPS,
     GLONASS, Galileo etc. are used for the reported position solution, the
     talker ID is ``Talker/GPS``, ``Talker/GLONASS``, ``Talker/galileo`` etc.
     and the DOP values pertain to the individual system. If GPS, GLONASS,
     Galileo, etc. are combined to obtain the reported position solution,
     multiple `GSA` sentences are produced, one with the GPS satellites, another
     with the GLONASS satellites another with Galileo, etc. each of these `GSA`
     sentences shall have talker ID ``Talker/GNSS``, to indicate that the
     satellites are used in a combined solution and each shall have the PDOP,
     HDOP and VDOP for the combined satellites used in the position.
    
     - Parameter PDOP: Position Dilution of Precision
     - Parameter HDOP: Horizontal Dilution of Precision
     - Parameter VDOP: Vertical Dilution of Precision
     - Parameter auto3D: If `true`, allowed to automatically switch 2D/3D; if
     `false`, forced to operate in 2D or 3D mode
     - Parameter solution: GNSS solution mode
     - Parameter ids: ID numbers of satellites used in solution
     - SeeAlso: ``geoPosition(_:time:isValid:mode:)``
     - SeeAlso: ``GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     */
    case GNSS_DOP(
      PDOP: Double,
      HDOP: Double,
      VDOP: Double,
      auto3D: Bool,
      solution: GNSS.SolutionType,
      ids: [GNSS.SatelliteID]
    )

    /**
     8.3.40 GST – GNSS pseudorange noise statistics
    
     This sentence is used to support receiver autonomous integrity monitoring
     (RAIM). Pseudorange measurement noise statistics can be translated in the
     position domain in order to give statistical measures of the quality of the
     position solution. If only GPS, GLONASS, Galileo, etc. is used for the
     reported position solution, the talker ID is ``Talker/GPS``,
     ``Talker/GLONASS``, ``Talker/galileo``, etc. and the error data pertain to
     the individual system. If satellites from multiple systems are used to
     obtain the position solution, the talker ID is ``Talker/GNSS`` and the
     errors pertain to the combined solution.
    
     - Parameter time: UTC time of the `GGA` or `GNS` fix associated with this sentence
     - Parameter rangeStddevRMS: RMS value of the standard deviation of the
     range inputs to the navigation process. Range inputs include pseudoranges
     and DGPS corrections.
     - Parameter errorSemimajorStddev: Standard deviation of semi-major axis of error ellipse (m)
     - Parameter errorSemiminorStddev: Standard deviation of semi-minor axis of error ellipse (m)
     - Parameter errorOrientation: Orientation of semi-major axis of error ellipse (°T)
     - Parameter errorLatitudeStddev: Standard deviation of latitude error (m)
     - Parameter errorLongitudeStddev: Standard deviation of longitude error (m)
     - Parameter errorAltitudeStddev: Standard deviation of altitude error (m)
     - SeeAlso: ``geoPosition(_:time:isValid:mode:)``
     - SeeAlso: ``GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
     */
    case GNSSPseudorangeNoise(
      time: Date,
      rangeStddevRMS: Double,
      errorSemimajorStddev: Measurement<UnitLength>,
      errorSemiminorStddev: Measurement<UnitLength>,
      errorOrientation: Bearing,
      errorLatitudeStddev: Measurement<UnitLength>,
      errorLongitudeStddev: Measurement<UnitLength>,
      errorAltitudeStddev: Measurement<UnitLength>
    )

    /**
     8.3.41 GSV – GNSS satellites in view
    
     Number of satellites (SV) in view, satellite ID numbers, elevation,
     azimuth, and SNR value. If multiple GPS, GLONASS, Galileo etc. satellites
     are in view, use separate `GSV` sentences with talker ID ``Talker/GPS`` to
     show the GPS satellites in view, talker ``Talker/GLONASS`` to show the
     GLONASS satellites in view and talker ID ``Talker/galileo`` to show the
     Galileo satellites in view, etc. When more than one ranging signal is used
     per satellite, also use separate `GSV` sentences with a signal ID
     corresponding to the ranging signal. The ``Talker/GNSS`` identifier shall
     not be used with this sentence.
    
     - Parameter satellites: Satellite information
     - Parameter total: Total number of satellites in view
     */
    case GNSSSatellitesInView(_ satellites: [GNSS.SatelliteInView], total: Int)

    /**
     8.3.42 HBT – Heartbeat supervision sentence
    
     This sentence is intended to be used to indicate that equipment is
     operating normally, or for supervision of a connection between two
     units.
    
     The sentence is transmitted at regular intervals specified in the
     corresponding equipment standard. The repeat interval may be used by
     the receiving unit to set the time-out value for the connection
     supervision.
    
     - Parameter interval: Configured autonomous repeat interval in seconds.
     This field should be set to NULL in response to a query if this
     feature is supported.
     - Parameter isNormal: Equipment in normal operation. This field can be
     used can be used to indicate the current equipment status. This could
     be the result of an built-in integrity testing function.
     - Parameter sequenceNumber: The sequential sentence identifier provides
     a message identification number from 0 to 9 that is sequentially
     assigned and is incremented for each new sentence. The count resets
     to 0 after 9 is used.
     */
    case heartbeat(interval: Measurement<UnitDuration>?, isNormal: Bool, sequenceNumber: Int)

    /**
     8.3.43 HDG – Heading, deviation and variation
    
     Heading (magnetic sensor reading), which if corrected for deviation
     will produce magnetic heading, which, if offset by variation, will
     provide true heading.
    
     - Parameter heading: Magnetic sensor heading, degrees
     - Parameter deviation: Magnetic deviation, degrees E/W
     - Parameter variation: Magnetic variation, degrees E/W
     */
    case heading(
      _ heading: Bearing,
      deviation: Measurement<UnitAngle>?,
      variation: Measurement<UnitAngle>?
    )

    /**
     8.3.44 HDT – Heading true
    
     Actual vessel heading in degrees true produced by any device or system
     producing true heading.
    
     - Parameter heading: Heading, degrees true
     - Note: This is a deprecated sentence which has been replaced by `THS`.
     - SeeAlso: ``trueHeadingMode(_:mode:)``
     */
    case trueHeading(_ heading: Bearing)

    /**
     8.3.45 HMR – Heading monitor receive
    
     Heading monitor receive: this sentence delivers data from the sensors
     selected by `HMS` from a central data collecting unit and delivers them
     to the heading monitor.
    
     - Parameter sensor1: Heading sensor 1 info
     - Parameter sensor2: Heading sensor 2 info
     - Parameter setDifference: Set difference by HMS, degrees
     - Parameter difference: Actual heading sensor difference, degrees
     - Parameter differenceOK: If `true`, difference within set limit. If
     `false`, difference exceeds set limit.
     - Parameter variation: Variation, degrees E/W
     - SeeAlso: ``headingMonitorSet(sensor1:sensor2:maxDiff:)``
     */
    case headingMonitorReceive(
      sensor1: HeadingSensor,
      sensor2: HeadingSensor,
      setDifference: Measurement<UnitAngle>,
      difference: Measurement<UnitAngle>,
      differenceOK: Bool,
      variation: Measurement<UnitAngle>?
    )

    /**
     8.3.46 HMS – Heading monitor set
    
     Set heading monitor: two heading sources may be selected and the
     permitted maximum difference may then be set.
    
     - Parameter sensor1: Heading sensor 1, ID
     - Parameter sensor2: Heading sensor 2, ID
     - Parameter maxDiff: Maximum difference, degrees. Maximum difference
     between both sensors which is accepted.
     */
    case headingMonitorSet(sensor1: String, sensor2: String, maxDiff: Measurement<UnitAngle>)

    /**
     8.3.47 HSC – Heading steering command
    
     Commanded heading to steer vessel. This is a command sentence and may
     be used to provide input to a heading controller or to report the
     heading that has been commanded. The `HTC` and `HTD` sentences are
     preferred for new applications, rather than the `HSC` sentence.
    
     - Parameter headingTrue: Commanded heading, degrees true
     - Parameter headingMagnetic: Commanded heading, degrees magnetic
     - Parameter status: This field is used to indicate a sentence that is a
     status report of current settings or a configuration command changing
     settings.
     - SeeAlso: ``headingControlCommand(heading:track:rudderAngle:override:mode:turnMode:rudderLimit:headingLimit:trackLimit:radius:rate:status:)``
     - SeeAlso: ``headingControlData(heading:track:rudderAngle:override:mode:turnMode:rudderLimit:headingLimit:trackLimit:radius:rate:rudderLimitExceeded:offHeading:offTrack:currentHeading:)``
     */
    case headingSteeringCommand(
      headingTrue: Bearing,
      headingMagnetic: Bearing,
      status: SentenceType
    )

    /**
     8.3.48 HSS – Hull stress surveillance systems
    
     This sentence indicates the hull stress surveillance system measurement data.
    
     - Parameter value: Measurement value
     - Parameter point: Measurement point ID
     - Parameter isValid: Data status
     */
    case hullStress(_ value: Double, point: String, isValid: Bool)

    /**
     8.3.49 HTC – Heading/track control command
    
     `HTC` is a command sentence. Provides input to (`HTC`) a heading
     controller to set values, modes and references; or provides output
     from (`HTD`) a heading controller with information about values, modes
     and references in use.
    
     - Parameter heading: Commanded heading-to-steer, degrees. Data in these
     fields should be related to the heading reference in use.
     - Parameter track: Commanded track. Commanded track represents the
     course line (leg) between two waypoints. It may be altered
     dynamically in a track-controlled turn along a pre-planned radius.
     Data in these fields should be related to the heading reference in
     use.
     - Parameter rudderAngle: Commanded rudder angle, degrees (port is negative)
     - Parameter override: Override provides direct control of the steering
     gear. In the context of this sentence, override means a temporary
     interruption of the selected steering mode. In this period, steering
     is performed by special devices. As long as this field is `true`,
     both fields `mode` and `turnMode` should be ignored by the
     heading/track controller and its computing parts should operate as if
     manual steering was selected.
     - Parameter mode: Selected steering mode
     - Parameter turnMode: Turn mode
     - Parameter rudderLimit: Commanded rudder limit, degrees (unsigned)
     - Parameter headingLimit: Commanded off-heading limit, degrees (unsigned)
     - Parameter trackLimit: Commanded off-track limit, n.miles (unsigned).
     Off-track status can be generated if the selected steering mode is
     ``Steering/Mode/trackControl``.
     - Parameter radius: Commanded radius of turn for heading changes, n.miles
     - Parameter rate: Commanded rate of turn for heading changes, °/min
     - Parameter status: Sentence status. This field is used to indicate a
     sentence that is a status report of current settings or a
     configuration command changing settings.
     - SeeAlso: ``headingControlData(heading:track:rudderAngle:override:mode:turnMode:rudderLimit:headingLimit:trackLimit:radius:rate:rudderLimitExceeded:offHeading:offTrack:currentHeading:)``
     */
    case headingControlCommand(
      heading: Bearing?,
      track: Bearing?,
      rudderAngle: Measurement<UnitAngle>?,
      override: Bool,
      mode: Steering.Mode,
      turnMode: Steering.TurnControl?,
      rudderLimit: Measurement<UnitAngle>?,
      headingLimit: Measurement<UnitAngle>?,
      trackLimit: Measurement<UnitLength>?,
      radius: Measurement<UnitLength>?,
      rate: Measurement<UnitAngularVelocity>?,
      status: SentenceType
    )

    /**
     8.3.49 HTD – Heading/track control data
    
     `HTC` is a command sentence. Provides input to (`HTC`) a heading
     controller to set values, modes and references; or provides output
     from (`HTD`) a heading controller with information about values, modes
     and references in use.
    
     - Parameter heading: Commanded heading-to-steer, degrees. Data in these
     fields should be related to the heading reference in use.
     - Parameter track: Commanded track. Commanded track represents the
     course line (leg) between two waypoints. It may be altered
     dynamically in a track-controlled turn along a pre-planned radius.
     Data in these fields should be related to the heading reference in
     use.
     - Parameter rudderAngle: Commanded rudder angle, degrees (port is negative)
     - Parameter override: Override provides direct control of the steering
     gear. In the context of this sentence, override means a temporary
     interruption of the selected steering mode. In this period, steering
     is performed by special devices. As long as this field is `true`,
     both fields `mode` and `turnMode` should be ignored by the
     heading/track controller and its computing parts should operate as if
     manual steering was selected.
     - Parameter mode: Selected steering mode
     - Parameter turnMode: Turn mode
     - Parameter rudderLimit: Commanded rudder limit, degrees (unsigned)
     - Parameter headingLimit: Commanded off-heading limit, degrees (unsigned)
     - Parameter trackLimit: Commanded off-track limit, n.miles (unsigned).
     Off-track status can be generated if the selected steering mode is
     ``Steering/Mode/trackControl``.
     - Parameter radius: Commanded radius of turn for heading changes, n.miles
     - Parameter rate: Commanded rate of turn for heading changes, °/min
     - Parameter rudderLimitExceeded: Rudder status, within limits (`false`)
     or exceeded (`true`)
     - Parameter offHeading: Off-heading status, within limits (`false`) or
     exceeded (`true`)
     - Parameter offTrack: Off-track status, within limits (`false`) or
     exceeded (`true`). Off-track status can be generated if the selected
     steering mode is ``Steering/Mode/trackControl``.
     - Parameter currentHeading: Vessel heading, degrees
     - SeeAlso: ``headingControlCommand(heading:track:rudderAngle:override:mode:turnMode:rudderLimit:headingLimit:trackLimit:radius:rate:status:)``
     */
    case headingControlData(
      heading: Bearing?,
      track: Bearing?,
      rudderAngle: Measurement<UnitAngle>?,
      override: Bool,
      mode: Steering.Mode,
      turnMode: Steering.TurnControl?,
      rudderLimit: Measurement<UnitAngle>?,
      headingLimit: Measurement<UnitAngle>?,
      trackLimit: Measurement<UnitLength>?,
      radius: Measurement<UnitLength>?,
      rate: Measurement<UnitAngularVelocity>?,
      rudderLimitExceeded: Bool,
      offHeading: Bool,
      offTrack: Bool,
      currentHeading: Bearing
    )

    /**
     8.3.54 LRI – AIS long-range interrogation,
     8.3.53 LRF – AIS long-range function
    
     The long-range interrogation of the AIS unit is accomplished through
     the use of two sentences. The pair of interrogation sentence
     formatters, a `LRI` sentence followed by a `LRF` sentence, provides the
     information needed by a universal AIS unit to determine if it should
     construct and provide the reply sentences (`LRF`, `LR1`, `LR2`, and
     `LR3`). The `LRI` sentence contains the information that the AIS unit
     needs in order to determine if the reply sentences need to be
     constructed. The `LRF` sentence identifies the information that needs
     to be in those reply sentences.
    
     The `LRF` sentence is used in both long-range interrogation requests
     and long-range interrogation replies. The `LRF`-sentence is the second
     sentence of the long-range interrogation request pair, `LRI` and `LRF`
     (see the `LRI`-sentence).
    
     - Parameter replyLogic: Control flag. The control flag affects AIS
     unit’s reply logic.
     - Parameter requestorMMSI: MMSI of requestor
     - Parameter requestorName: Name of requestor
     - Parameter destination: MMSI or geographic area of destination
     - Parameter functions: Function request
     - SeeAlso: ``AISLongRangeReply(requestorMMSI:requestorName:replyStatuses:time:shipName:shipCallsign:shipIMO:position:course:speed:destination:ETA:shipType:shipType2:length:breadth:draught:soulsOnboard:)``
     */
    case AISLongRangeInterrogation(
      replyLogic: AISLongRange.ReplyLogic,
      requestorMMSI: Int,
      requestorName: String,
      destination: AISLongRange.Destination,
      functions: Set<AISLongRange.Function>
    )

    /**
     8.3.53 LRF – AIS long-range function,
     8.3.50 LR1 – AIS long-range reply sentence 1,
     8.3.51 LR2 – AIS long-range reply sentence 2,
     8.3.52 LR3 – AIS long-range reply sentence 3
    
     The `LRF`-sentence is the first sentence of the long-range
     interrogation reply. The minimum reply consists of a `LRF`-sentence
     followed by a `LR1`-sentence. The `LR2`-sentence and/or the
     `LR3`-sentence follow the `LR1`-sentence if information provided in
     these sentences was requested by the interrogation. Fields not included
     in the interrogation reply are `nil`.
    
     The `LR1` sentence identifies the destination for the reply and
     contains the information items requested by the
     ``AISLongRange/Function/shipID`` function (see the `LRF` sentence).
    
     The `LR2`-sentence contains the information items requested by the
     ``AISLongRange/Function/dateTime``, ``AISLongRange/Function/position``,
     ``AISLongRange/Function/course``, and ``AISLongRange/Function/speed``
     functions (see the `LRF` sentence).
    
     The `LR3` sentence contains the information items requested by the
     ``AISLongRange/Function/destination``, ``AISLongRange/Function/draught``,
     ``AISLongRange/Function/cargo``, ``AISLongRange/Function/shipDimensions``,
     and ``AISLongRange/Function/soulsOnboard`` functions (see the `LRF`
     sentence).
    
     - Parameter requestorMMSI: MMSI of requestor
     - Parameter requestorName: Name of requestor, 1 to 20 character
     - Parameter replyStatuses: Function reply status
     - Parameter time: UTC time of position
     - Parameter shipName: Ship’s name, 1 to 20 characters
     - Parameter shipCallsign: Call sign, 1 to 7 characters
     - Parameter shipIMO: IMO number, 9-digit number
     - Parameter position: Ship's position at `time`
     - Parameter course: Course over ground, degrees, true
     - Parameter speed: Speed over ground, knots
     - Parameter destination: Voyage destination, 1 to 20 chars
     - Parameter ETA: Estimated time of arrival at destination
     - Parameter shipType: Ship/cargo
     - Parameter shipType2: Ship type (appears twice in spec for some reason?)
     - Parameter length: Ship length, meters
     - Parameter breadth: Ship breadth, meters
     - Parameter draught: Draught, meters
     - Parameter soulsOnboard: Persons, 0 to 8191
     - SeeAlso: ``AISLongRangeInterrogation(replyLogic:requestorMMSI:requestorName:destination:functions:)``
     */
    case AISLongRangeReply(
      requestorMMSI: Int,
      requestorName: String?,
      replyStatuses: [AISLongRange.Function: AISLongRange.FunctionStatus],
      time: Date?,
      shipName: String?,
      shipCallsign: String?,
      shipIMO: Int?,
      position: Position?,
      course: Bearing?,
      speed: Measurement<UnitSpeed>?,
      destination: String?,
      ETA: Date?,
      shipType: AISLongRange.ShipType?,
      shipType2: AISLongRange.ShipType?,
      length: Measurement<UnitLength>?,
      breadth: Measurement<UnitLength>?,
      draught: Measurement<UnitLength>?,
      soulsOnboard: Int?
    )

    /**
     8.3.55 MEB – Message input for broadcast command
    
     This sentence is used to input a message for storage or immediate
     broadcast. The sentence associates messages with real, virtual, and
     synthetic MMSIs.
    
     The stored message is associated by the MMSI, Message ID, and Message
     ID Index. The combination of MMSI, Message ID, and Message ID Index are
     used to reference the stored message and link the message to a
     transmission schedule as defined by a `CBR` sentence. The stored
     message’s broadcast begins when both the message content and schedule
     have been entered.
    
     For immediate message broadcast, the binary data will be broadcast
     using the slots reserved by the `CBR` sentence with both Message ID and
     Message ID Index = 0, or will be broadcast within 4 s according to
     RATDMA rules. The channel for the immediate message broadcast is
     specified by `AISChannel`.
    
     This sentence can be queried. When queried, the query response may
     contain one or more sentences and will continue until the transfer of
     all stored information is complete.
    
     - Parameter sequence: Sequential message identifier. This sequential
     message identifier serves two purposes. It meets the requirements as
     stated in 7.3.4 and it is the sequence number utilized by
     ITU-R M.1371 in message types ``AIS/MessageID/addressedBinary`` and
     ``AIS/MessageID/addressedSafety``. The range of this field is
     restricted by ITU-R M1371 to 0 to 3. The sequential message identifier
     value may be reused after the AIS unit provides the `ABK`
     acknowledgement for this number. See
     ``AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``.
     - Parameter AISChannel: AIS channel for broadcast of the radio message.
     For an immediate message broadcast, this cannot be `nil`. For a
     stored message it should be `nil`.
     - Parameter MMSI: For the message to be broadcast, this MMSI should
     match a previously entered real, virtual, or synthetic MMSI.
     - Parameter messageID: ITU-R M.1371 Message ID. ITU-R M.1371 messages
     supported by this sentence: 6, 8, 12, 14, 25, and 26. See IEC 62320-2
     for the ITU-R M.1371 messages that are supported by an AIS AtoN station.
     - Parameter messageIndex: Message ID Index
     - Parameter broadcastBehavior: Broadcast behaviour
     - Parameter destinationMMSI: Destination MMSI, for addressed messages
     - Parameter binaryStructure: Binary data flag
     - Parameter sentenceType: Sentence status flag
     - Parameter data: Encapsulated data. This is the content of the “binary
     data” parameter for either ITU-R M.1371 Message 6, 8, 25, or 26, or
     the “safety related text” parameter for either Message 12 or 14.
     - SeeAlso: ``navaidMessageBroadcastRates(MMSI:message:index:channelA:scheduleType:channelB:type:)``
     - SeeAlso: ``AISBroadcastAcknowledgement(MMSI:channel:messageID:sequence:type:)``
     */
    case broadcastMessage(
      sequence: Int,
      AISChannel: AIS.BroadcastChannel?,
      MMSI: Int,
      messageID: AIS.MessageID,
      messageIndex: Int,
      broadcastBehavior: AIS.BroadcastBehavior,
      destinationMMSI: Int?,
      binaryStructure: AIS.BinaryDataStructure,
      sentenceType: SentenceType,
      data: Data
    )

    /**
     8.3.56 MSK – MSK receiver interface
    
     This is a command sentence. This sentence is used to set the controls
     of a radiobeacon MSK receiver (beacon receiver) or to report the status
     of an MSK receiver’s controls in response to a query sentence.
    
     - Parameter frequency: Beacon frequency, 283,5 kHz to 325,0 kHz
     - Parameter bitRate: Beacon bit rate (25, 50, 100, 200) bits/s
     - Parameter statusInterval: Interval for sending
     ``MSKReceiverSignalStatus(signalStrength:SNR:frequency:bitRate:channel:)``
     in seconds
     - Parameter channel: Channel number. Set equal to "1" or `nil` for
     single channel receivers.
     - Parameter status: This field is used to indicate a sentence that is a
     status report of current settings or a configuration command changing
     settings.
     */
    case MSKReceiverInterface(
      frequency: MSK.AutoMeasurement<UnitFrequency>,
      bitRate: MSK.AutoMeasurement<UnitInformationTransferRate>,
      statusInterval: Measurement<UnitDuration>?,
      channel: Int?,
      status: SentenceType
    )

    /**
     8.3.57 MSS – MSK receiver signal status
    
     Signal-to-noise ratio, signal strength, frequency and bit rate from a
     MSK beacon receiver.
    
     - Parameter signalStrength: Signal strength (SS), dB/1 µV/m
     - Parameter SNR: Signal-to-noise ratio (SNR), dB
     - Parameter frequency: Beacon frequency, 283,5 kHz to 325,0 kHz
     - Parameter bitRate: Beacon bit rate (25, 50, 100, 200) bits/s
     - Parameter channel: Channel number. Set equal to "1" or `nil` for
     single channel receivers.
     */
    case MSKReceiverSignalStatus(
      signalStrength: Double,
      SNR: Double,
      frequency: Measurement<UnitFrequency>,
      bitRate: Measurement<UnitInformationTransferRate>,
      channel: Int?
    )

    /**
     8.3.58 MTW – Water temperature
    
     - Parameter temperature: Temperature, degrees C
     */
    case waterTemperature(_ temperature: Measurement<UnitTemperature>)

    /**
     8.3.59 MWD – Wind direction and speed
    
     The direction from which the wind blows across the earth’s surface,
     with respect to north, and the speed of the wind.
    
     - Parameter directionTrue: Wind direction, 0° to 359° true
     - Parameter directionMagnetic: Wind direction, 0° to 359° magnetic
     - Parameter speedKnots: Wind speed, knots
     - Parameter speedMps: Wind speed, m/s
     */
    case windDirectionSpeed(
      directionTrue: Bearing,
      directionMagnetic: Bearing,
      speedKnots: Measurement<UnitSpeed>,
      speedMps: Measurement<UnitSpeed>
    )

    /**
     8.3.60 MWV – Wind speed and angle
    
     See ``RelativeWindReference`` for a discussion on relative winds.
    
     - Parameter angle: Wind angle, 0° to 359°
     - Parameter speed: Wind speed
     - Parameter reference: Angle and speed reference
     - Parameter isValid: Data valid or invalid
     */
    case windAngleSpeed(
      angle: Measurement<UnitAngle>,
      speed: Measurement<UnitSpeed>,
      reference: RelativeWindReference,
      isValid: Bool
    )

    /**
     8.3.61 NAK – Negative acknowledgement
    
     In general, the `NAK` sentence is used when a reply to a query sentence
     cannot be provided, or when a command sentence is not accepted.
    
     The `NAK` sentence reply should be generated within 1 s.
    
     This sentence cannot be queried.
    
     - Parameter talker: Talker identifier from the sentence formatter that
     caused the `NAK` generation.
     - Parameter format: Affected sentence formatter. Affected sentence
     formatter is either the “approved sentence formatter of data” being
     requested in a query that cannot be processed or accepted, or the
     sentence formatter of the control or configuration sentence that
     cannot be processed or accepted.
     - Parameter uniqueID: The unique identifier is used for system level
     identification of a device, 15 characters maximum. This is the unique
     identifier for the device producing the `NAK` sentence, when available.
     - Parameter reasonCode: Reason code for negative acknowledgement
     - Parameter reason: Negative acknowledgement’s descriptive text. The
     length of this field is constrained by the maximum sentence length.
     */
    case negativeAcknowledgement(
      talker: Talker,
      format: Format,
      uniqueID: String?,
      reasonCode: NAKReason,
      reason: String?
    )

    /**
     8.3.62 NRM – NAVTEX receiver mask
    
     This command is used to manipulate the configuration masks that control
     which messages are stored, printed and sent to the INS port of the
     NAVTEX receiver. This a command sentence.
    
     - Parameter function: The function code is used to further identify the
     purpose of the sentence.
     - Parameter frequency: The frequency indicator identifies the frequency
     that the NAVTEX message was received on.
     - Parameter coverageAreaMask: Transmitter coverage area mask
     - Parameter messageTypeMask: Message type mask
     - Parameter status: Sentence status flag
     */
    case NAVTEXReceiverMask(
      function: NAVTEX.FunctionCode,
      frequency: NAVTEX.Frequency,
      coverageAreaMask: NAVTEX.Mask?,
      messageTypeMask: NAVTEX.Mask?,
      status: SentenceType
    )

    /**
     8.3.63 NRX – NAVTEX received message
    
     The `NRX` sentence is used to transfer the contents of a received
     NAVTEX message from the NAVTEX receiver to another device. As the
     length of a single NAVTEX message may exceed the number of characters
     permitted in a single sentence, many `NRX` sentences may be required to
     transfer a single NAVTEX message.
    
     - Parameter message: Message body
     - Parameter id: Sequential message id. The sequential message
     identifier provides a unique identifier for each NAVTEX message
     represented by a group of sentences. Though `code` contains a NAVTEX
     message serial number, there are special cases when the message
     serial number is set to 00 and has a different meaning or when the
     same message code can occur more than once. When these conditions
     occur, the sequential message identifier can be relied upon to
     uniquely identify this NAVTEX message from other NAVTEX messages with
     the same message code.
     - Parameter frequency: The frequency indicator identifies the frequency
     that the NAVTEX message was received on.
     - Parameter code: The NAVTEX message code contains three related
     entities. The first character identifies the transmitter coverage
     area and the second character identifies the type of message. Both
     these characters are as defined in Table I of Recommendation ITU-R
     M.625-3, combination numbers 1 to 26. Transmitter identification
     characters are allocated by the IMO NAVTEX Co-ordinating Panel; these
     characters and the meanings of the message type characters are
     described in the NAVTEX manual (IMO publication 951E). The remaining
     two characters are restricted to numerals with a range of 00 to 99
     and represent a serial number for each type of message. The value of
     00 is a special case and not considered a serial number. See
     IEC 61097-6 for interpretation of special case value of 00.
     - Parameter time: UTC of receipt of message
     - Parameter totalCharacters: Total number of characters in this series
     of `NRX` sentences
     - Parameter badCharacters: Total number of bad characters
     - Parameter isValid: `true` is used for syntactically correct message
     reception. `false` is used for syntactically incorrect message
     reception, for example end characters NNNN missing.
     */
    case NAVTEXMessage(
      _ message: String,
      id: Int,
      frequency: NAVTEX.Frequency,
      code: String,
      time: Date,
      totalCharacters: Int,
      badCharacters: Int,
      isValid: Bool
    )

    /**
     8.3.64 OSD – Own ship data
    
     Heading, course, speed, set and drift summary. Useful for, but not
     limited to radar/ARPA applications. `OSD` gives the movement vector of
     the ship based on the sensors and parameters in use.
    
     - Parameter heading: Heading, degrees true
     - Parameter headingValid: Heading status
     - Parameter course: Vessel course, degrees true
     - Parameter reference: Course reference
     - Parameter speed: Vessel speed
     - Parameter speedReference: Speed reference
     - Parameter set: Vessel set, degrees true
     - Parameter drift: Vessel drift (speed)
     */
    case ownshipData(
      heading: Bearing,
      headingValid: Bool,
      course: Bearing,
      courseReference: CourseSpeedReference,
      speed: Measurement<UnitSpeed>,
      speedReference: CourseSpeedReference,
      set: Bearing,
      drift: Measurement<UnitSpeed>
    )

    /**
     8.3.65 POS – Device position and ship dimensions report or configuration command
    
     This sentence is used to report the device position (X, Y, and Z) of
     the equipment such as GNSS and radar antenna installed on board a ship
     and the ship dimensions. The consistent common reference position
     (CCRP) data may also be provided. This sentence can be used to
     configure or report the status and can be queried. This is a command
     sentence. Usage is defined in equipment standards. Possible application
     may be to transmit this sentence at power up and repeatedly at
     30 second interval.
    
     - Parameter equipment: Equipment identification
     - Parameter equipmentNumber: Equipment number 00 to 99. Equipment
     number starts from one to maximum same equipment number. (e.g.
     1 = Radar 1, 2 = Radar 2). Equipment number “0” is used for CCRP
     position (see IMO MSC.252(83)).
     - Parameter positionValid: Position validity flag
     - Parameter position: Ship's position
     - Parameter dimensionsValid: Ship’s width/length Valid/Invalid
     - Parameter dimensions: Ship's dimensions
     - Parameter status: Sentence status flag
     */
    case positionDimensions(
      equipment: Talker,
      equipmentNumber: Int,
      positionValid: Bool,
      position: Coordinate,
      dimensionsValid: Bool,
      dimensions: Dimensions,
      status: SentenceType
    )

    /**
     8.3.66 PRC – Propulsion remote control status
    
     This sentence indicates the engine control status (engine order) on a
     remote control system. This provides the detailed data not available
     from the engine telegraph sentence `ETL`. The sentence shall be
     transmitted at regular intervals.
    
     - Parameter leverDemandPosition: Lever position of engine telegraph
     demand. −100 to 0 to 100 % from “full astern” (crash astern) to
     “full ahead” (navigation full) “ stop engine”
     - Parameter leverDemandValid: Lever demand status
     - Parameter RPMDemand: RPM demand value
     - Parameter pitchDemand: Pitch demand value
     - Parameter location: Operating location indicator
     - Parameter engineNumber: Numeric character to identify engine or
     propeller shaft controlled by the system. This is numbered from
     centre-line. This field is a single character.
     - SeeAlso: ``engineTelegraph(time:type:position:subPosition:location:number:)``
     */
    case propulsionRemoteControl(
      leverDemandPosition: Double,
      leverDemandValid: Bool,
      RPMDemand: Propulsion.RPMValue,
      pitchDemand: Propulsion.PitchValue,
      location: Propulsion.Location?,
      engineNumber: Int
    )

    /**
     8.3.67 RMA – Recommended minimum specific LORAN-C data
    
     Position, course and speed data provided by a LORAN-C receiver. Time
     differences A and B are those used in computing latitude/longitude.
     This sentence is transmitted at intervals not exceeding 2 s and is
     always accompanied by `RMB` when a destination waypoint is active. `RMA`
     and `RMB` are the recommended minimum data to be provided by a LORAN-C
     receiver. All data fields should be provided, `nil` fields are used only
     when data is temporarily unavailable.
    
     - Parameter isValid: Data valid, or blink/cycle/SNR warning
     - Parameter position: LORAN-C position
     - Parameter timeDifferenceA: Time difference A, ms
     - Parameter timeDifferenceB: Time difference B, ms
     - Parameter speed: Speed over ground, knots
     - Parameter course: Course over ground, degrees true
     - Parameter magneticVariation: Magnetic variation, degrees E (-) / W (+)
     - Parameter mode: Mode indicator. The positioning system mode indicator
     supplements the `isValid` field, which should be `false` for all
     values of Mode indicator except for ``Navigation/Mode/autonomous`` and
     ``Navigation/Mode/differential``.
     - SeeAlso: ``destinationMinimumData(isValid:crossTrackError:originID:destinationID:destination:rangeToDestination:bearingToDestination:closingVelocity:isArrived:mode:)``
     */
    case LORANCMinimumData(
      isValid: Bool,
      position: Position?,
      timeDifferenceA: Measurement<UnitDuration>?,
      timeDifferenceB: Measurement<UnitDuration>?,
      speed: Measurement<UnitSpeed>?,
      course: Bearing?,
      magneticVariation: Measurement<UnitAngle>?,
      mode: Navigation.Mode
    )

    /**
     8.3.68 RMB – Recommended minimum navigation information
    
     Navigation data from present position to a destination waypoint
     provided by a LORAN-C, GNSS, navigation computer or other integrated
     navigation system. This sentence always accompanies `RMA` or `RMC`
     sentences when a destination is active when provided by a LORAN-C, or
     GNSS receiver, other systems may transmit `RMB` without `RMA` or
     `RMC`.
    
     - Parameter isValid: Data valid, or navigation receiver warning
     - Parameter crossTrackError: Cross track error, nautical miles. If
     cross track error exceeds 9,99 nautical miles, display 9,99. (left =
     negative)
     - Parameter originID: Origin waypoint ID
     - Parameter destinationID: Destination waypoint ID
     - Parameter destination: Destination waypoint position
     - Parameter rangeToDestination: Range to destination, nautical miles.
     If range to destination exceeds 999,9 nautical miles, display 999,9.
     - Parameter bearingToDestination: Bearing to destination, degrees true
     - Parameter closingVelocity: Destination closing velocity, knots
     - Parameter isArrived: arrival circle entered, or perpendicular passed
     - Parameter mode: Mode indicator
     - SeeAlso: ``LORANCMinimumData(isValid:position:timeDifferenceA:timeDifferenceB:speed:course:magneticVariation:mode:)``
     - SeeAlso: ``GNSSMinimumData(time:isValid:position:speed:course:magneticVariation:mode:status:)``
     */
    case destinationMinimumData(
      isValid: Bool,
      crossTrackError: Measurement<UnitLength>,
      originID: String,
      destinationID: String,
      destination: Position,
      rangeToDestination: Measurement<UnitLength>,
      bearingToDestination: Bearing,
      closingVelocity: Measurement<UnitSpeed>,
      isArrived: Bool,
      mode: Navigation.Mode
    )

    /**
     8.3.69 RMC – Recommended minimum specific GNSS data
    
     Time, date, position, course and speed data provided by a GNSS
     navigation receiver. This sentence is transmitted at intervals not
     exceeding 2 s and is always accompanied by `RMB` when a destination
     waypoint is active. `RMC` and `RMB` are the recommended minimum data to
     be provided by a GNSS receiver. All data fields should be provided,
     `nil` fields used only when data is temporarily unavailable.
    
     - Parameter time: UTC of position fix
     - Parameter isValid: data valid, or navigation receiver warning
     - Parameter position: Latitude and longitude of position
     - Parameter speed: Speed over ground, knots
     - Parameter course: Course over ground, degrees true
     - Parameter magneticVariation: Magnetic variation, degrees, E/W.
     Easterly variation subtracts from True course, Westerly variation
     adds to True course.
     - Parameter mode: Mode indicator. The positioning system mode indicator
     supplements the `isValid` field, which should be `false` for all
     values of Mode indicator except for ``Navigation/Mode/autonomous`` and
     ``Navigation/Mode/differential``.
     - Parameter status: Navigational status. The navigational status
     indicator is according to IEC 61108 requirements on ‘Navigational (or
     Failure) warnings and status indications’.
     - SeeAlso: ``destinationMinimumData(isValid:crossTrackError:originID:destinationID:destination:rangeToDestination:bearingToDestination:closingVelocity:isArrived:mode:)``
     */
    case GNSSMinimumData(
      time: Date,
      isValid: Bool,
      position: Position,
      speed: Measurement<UnitSpeed>,
      course: Bearing,
      magneticVariation: Measurement<UnitAngle>,
      mode: Navigation.Mode,
      status: GNSS.IntegrityStatus
    )

    /**
     8.3.70 ROR – Rudder order status
    
     Angle ordered for the rudder. Relative measurement of rudder order
     angle without units, "-" = bow turns to port.
    
     - Parameter starboard: Starboard (or single) rudder order
     - Parameter port: Port rudder order
     - Parameter starboardValid: Data valid or invalid
     - Parameter portValid: Data valid or invalid
     - Parameter commandSource: Command source location
     */
    case rudderOrder(
      starboard: Double,
      port: Double?,
      starboardValid: Bool,
      portValid: Bool?,
      commandSource: Propulsion.Location
    )

    /**
     8.3.71 ROT – Rate of turn
    
     Rate of turn and direction of turn.
    
     - Parameter rate: Rate of turn, °/min, "-" = bow turns to port
     - Parameter isValid: Data valid or invalid
     */
    case rateOfTurn(rate: Measurement<UnitAngularVelocity>, isValid: Bool)

    /**
     8.3.72 RPM – Revolutions
    
     Shaft or engine revolution rate and propeller pitch
    
     - Parameter source: Source, shaft or engine
     - Parameter number: Engine or shaft number, numbered from centre-line.
     Odd = starboard, even = port, 0 = single or on centre-line
     - Parameter speed: Speed, revolutions/min, "-" = counter-clockwise
     - Parameter pitch: Propeller pitch, % of maximum, "-" = astern
     - Parameter isValid: Data valid or invalid
     */
    case revolutions(
      source: Propulsion.ThrustSource,
      number: Int,
      speed: Measurement<UnitAngularVelocity>,
      pitch: Double,
      isValid: Bool
    )

    /**
     8.3.73 RSA – Rudder sensor angle
    
     Relative rudder angle,from rudder angle sensor. Relative measurement of
     rudder angle without units, "-" = bow turns to port. Sensor output is
     proportional to rudder angle but not necessarily 1:1.
    
     - Parameter starboard: Starboard (or single) rudder sensor
     - Parameter port: Port rudder sensor
     - Parameter starboardValid: Data valid or invalid
     - Parameter portValid: Data valid or invalid
     */
    case rudderSensorAngle(starboard: Double, port: Double?, starboardValid: Bool, portValid: Bool?)

    /**
     8.3.74 RSD – Radar system data
    
     Radar display setting data. Origin 1 and origin 2 are located at the
     stated range and bearing from own ship and provide for two independent
     sets of variable range markers (VRM) and electronic bearing lines (EBL)
     originating away from own ship position.
    
     - Parameter origin1: Origin 1
     - Parameter VRM1: Variable range marker 1
     - Parameter EBL1: Bearing line 1, degrees from 0°
     - Parameter origin2: Origin 2
     - Parameter VRM2: Variable range marker 2
     - Parameter EBL2: Bearing line 1, degrees from 0°
     - Parameter cursor: Cursor range, from own ship, and bearing, degrees
     clockwise from 0°
     - Parameter rangeScale: Range scale in use
     - Parameter rotation: Display rotation
     */
    case radarSystemData(
      origin1: BearingRange,
      VRM1: Measurement<UnitLength>,
      EBL1: Bearing,
      origin2: BearingRange,
      VRM2: Measurement<UnitLength>,
      EBL2: Bearing,
      cursor: BearingRange,
      rangeScale: Measurement<UnitLength>,
      rotation: DisplayRotation
    )

    /**
     8.3.75 RTE – Routes
    
     Waypoint identifiers, listed in order with starting waypoint first, for
     the identified route. Two modes of transmission are provided:
     ``Navigation/RouteType/complete`` indicates that the complete list of waypoints
     in the route is being transmitted; ``Navigation/RouteType/working`` indicates a
     working route where the first listed waypoint is always the last
     waypoint that had been reached (FROM), while the second listed waypoint
     is always the waypoint that the vessel is currently heading for (TO)
     and the remaining list of waypoints represents the remainder of the
     route.
    
     - Parameter mode: Message mode
     - Parameter identifier: Route identifier
     - Parameter waypoints: Waypoint identifiers
     */
    case route(mode: Navigation.RouteType, identifier: String, waypoints: [String])

    /**
     8.3.76 SFI – Scanning frequency information
    
     This sentence is used to set frequencies and mode of operation for
     scanning purposes and to acknowledge setting commands. Scanning
     frequencies are listed in order of scanning. For DSC distress and
     safety watchkeeping only six channels shall be scanned in the same
     scanning sequence. To indicate a frequency set at the scanning
     receiver, use `FSI` sentence.
    
     - Parameter frequencies: Frequencies or ITU channels, with mode of operation
     - SeeAlso: ``frequencySetInfo(transmit:receive:mode:powerLevel:type:)``
     */
    case scanningFrequencies(_ frequencies: [Comm.FrequencyMode])

    /**
     8.3.77 SSD – AIS ship static data
    
     This sentence is used to enter static parameters into a shipboard AIS
     unit. The parameters in this sentence support a number of the
     ITU-R M.1371 Messages.
    
     - Parameter callsign: Ship’s call sign, 1 to 7 characters. A `nil`
     field indicates that the previously entered call sign is unchanged.
     - Parameter name: Ship’s name, 1 to 20 characters
     - Parameter pointA: Pos. ref., point dist. “A,” from bow, 0 to 511 m.
     A `nil` field indicates that the previously entered value is unchanged.
     - Parameter pointB: Pos. ref., point dist. “B,” from stern, 0 to 511 m
     A `nil` field indicates that the previously entered value is unchanged.
     - Parameter pointC: Pos. ref., point dist. “C,” from port beam, 0 to 63 m
     A `nil` field indicates that the previously entered value is unchanged.
     - Parameter pointD: Pos. ref., point dist. “D,” from starboard beam, 0 TO 63 m
     A `nil` field indicates that the previously entered value is unchanged.
     - Parameter DTEAvailable: DTE indicator flag. The DTE indicator is an
     abbreviation for data terminal equipment indicator. The purpose of
     the DTE indicator is to inform distant receiving applications that,
     if set to “available,” the transmitting station conforms, at least,
     to the minimum keyboard and display requirements. The DTE indicator
     is only used as information provided to the application layer –
     indicating that the transmitting station is available for
     communications. On the transmitting side, the DTE indicator may be
     set by an external application using this sentence. DTE indicator
     flag values are: `true` = Keyboard and display are a standard
     configuration, and communication is supported; `false` = Keyboard and
     display are either unknown or unable to support communication.
     - Parameter source: Source identifier. The source identifier contains
     the talker ID of the position source at the location on the ship
     defined by `pointA` through `pointD`. The source identifier of
     ``Talker/automaticID`` should be used for the AIS units internal
     position source. This data field helps the AIS to distinguish the
     position information source for the purpose of changing the
     information broadcast in VDL message 5 for the location of position
     sensor antenna on the vessel.
     */
    case AISShipStaticData(
      callsign: AIS.Availability<String>?,
      name: AIS.Availability<String>,
      pointA: AIS.Availability<Measurement<UnitLength>>?,
      pointB: AIS.Availability<Measurement<UnitLength>>?,
      pointC: AIS.Availability<Measurement<UnitLength>>?,
      pointD: AIS.Availability<Measurement<UnitLength>>?,
      DTEAvailable: Bool,
      source: Talker
    )

    /**
     8.3.78 STN – Multiple data ID
    
     This sentence is transmitted before each individual sentence where
     there is a need for the listener to determine the exact source of data
     in a system. Examples might include dual-frequency depth sounding
     equipment or equipment that integrates data from a number of sources
     and produces a single output.
    
     - Parameter ID: Talker ID number, 00 to 99
     */
    case talkerID(_ ID: Int)

    /**
     8.3.79 THS – True heading and status
    
     Actual vessel heading in degrees true produced by any device or system
     producing true heading. This sentence includes a “mode indicator” field
     providing critical safety related information about the heading data,
     and replaces the deprecated `HDT` sentence.
    
     - Parameter heading: Heading, degrees true
     - Parameter mode: Mode indicator
     - Note: This sentence replaces the deprecated sentence `HDT`.
     - SeeAlso: ``trueHeading(_:)``
     */
    case trueHeadingMode(_ heading: Bearing, mode: Heading.Mode)

    /**
     8.3.80 TLB – Target label
    
     Common target labels for tracked targets. This sentence is used to
     specify labels for tracked targets to a device that provides tracked
     target data (e.g. via `TTM`). This will allow all devices displaying
     tracked target data to use a common set of labels (e.g. targets
     reported by two radars and displayed on an ECDIS).
    
     - Parameter labels: Target number ‘n’ reported by the device, and
     label assigned to target ‘n’
     - SeeAlso: ``trackedTarget(number:distance:bearing:speed:course:CPADistance:CPATime:name:status:isReference:time:acquisition:)``
     - Note: `nil` fields indicate that no common label is specified, not
     that a null label should be used. The intent is to use a `nil` field as
     a place holder. A device that provides tracked target data should use
     its ”local” label (usually the target number) unless it has received a
     `TLB` sentence specifying a common label.
     */
    case targetLabels(_ labels: [Int: String?])

    /**
     8.3.81 TLL – Target latitude and longitude
    
     Target number, name, position and time tag for use in systems tracking
     targets.
    
     - Parameter number: Target number 00 – 99
     - Parameter position: Target latitude and longitude
     - Parameter name: Target name
     - Parameter time: UTC of data
     - Parameter status: Target status
     - Parameter isReference: Reference target: `true` if target is a
     reference used to determine own ship’s position or velocity.
     */
    case targetPosition(
      number: Int,
      position: Position,
      name: String,
      time: Date,
      status: Radar.TargetStatus,
      isReference: Bool
    )

    /**
     8.3.82 TRC – Thruster control data
    
     This sentence provides the status of control data for thruster devices.
     This sentence may also be used as a command sentence. When providing
     status data the sentence shall be transmitted at regular intervals.
    
     - Parameter number: Number of thruster, bow or stern. This is numbered
     from centre-line. This field is single digit: Odd = Bow thruster,
     Even = Stern thrusters
     - Parameter RPMDemand: RPM demand value
     - Parameter pitchDemand: Pitch demand value
     - Parameter azimuthDemand: Azimuth demand. Direction of thrust in
     degrees (0° – 360°).
     - Parameter location: Operating location indicator
     - Parameter status: Sentence status flag
     */
    case thrusterControl(
      number: Int,
      RPM: Propulsion.RPMValue,
      pitch: Propulsion.PitchValue,
      azimuth: Measurement<UnitAngle>?,
      location: Propulsion.Location,
      status: SentenceType
    )

    /**
     8.3.83 TRD – Thruster response data
    
     This sentence provides the response data for thruster devices.
    
     - Parameter number: Number of thruster, bow or stern. This is numbered
     from centre-line. This field is single digit: Odd = Bow thruster,
     Even = Stern thrusters
     - Parameter RPM: RPM response
     - Parameter pitch: Pitch response value
     - Parameter azimuth: Azimuth response
     */
    case thrusterResponse(
      number: Int,
      RPM: Propulsion.RPMValue,
      pitch: Propulsion.PitchValue,
      azimuth: Measurement<UnitAngle>?
    )

    /**
     8.3.84 TTD – Tracked target data
    
     This sentence is used to transmit tracked radar targets in a compressed
     format. This enables the transfer of many targets with minimum
     overhead. New target labels are defined by the `TLB` sentence to reduce
     bandwidth use. Transmission of up to four targets in the same sentence
     is possible.
    
     - Parameter targets: Tracked target data
     - SeeAlso: ``targetLabels(_:)``
     */
    case trackedTargets(_ targets: [Radar.TrackedTarget])

    /**
     8.3.85 TTM – Tracked target message
    
     Data associated with a tracked target relative to own ship's position.
    
     - Parameter number: Target number, 00 to 99
     - Parameter distance: Target distance from own ship
     - Parameter bearing: Bearing from own ship, degrees true/relative
     - Parameter speed: Target speed
     - Parameter course: Target course, degrees true/relative
     - Parameter CPADistance: Distance of closest-point-of-approach
     - Parameter CPATime: Time to CPA, min., "-" increasing
     - Parameter name: Target name
     - Parameter status: Target status
     - Parameter isReference: Reference target: set to `true` if target is a
     reference used to determine own ship’s position or velocity, `false`
     otherwise.
     - Parameter time: Time of data (UTC)
     - Parameter acquisition: Type of acquisition
     */
    case trackedTarget(
      number: Int,
      distance: Measurement<UnitLength>,
      bearing: Bearing,
      speed: Measurement<UnitSpeed>,
      course: Bearing,
      CPADistance: Measurement<UnitLength>,
      CPATime: Measurement<UnitDuration>,
      name: String,
      status: Radar.TargetStatus,
      isReference: Bool,
      time: Date,
      acquisition: Radar.AcquisitionType
    )

    /**
     8.3.86 TUT – Transmission of multi-language text
    
     A sentence to support multi-language text using a variable length Hex
     field in the sentence definition.
    
     The sentence structure is similar to the `TXT` sentence, however, it
     has two additional fields. There is a “source identifier” field used to
     identify the origin of the sentence and a “translation code” field that
     is used to define the coding system for the text body. This enables the
     use of multi-language codes, such as, unicode or other codes. A
     proprietary look-up table method is incorporated to allow pre-defined
     messages to be sent in short sentences.
    
     If `translationCode` is `U` (Unicode, ISO 10646-1), `A` (ASCII), or `1`
     through `16` (ISO 8859-1 through -16), then `text` will contain the
     decoded string. If `translationCode` is `Pxxx` (proprietary), `text`
     will be `nil` and `data` will contain the undecoded string.
    
     - Parameter source: Source identifier
     - Parameter text: Text body, if `data` is encoded in a
     non-proprietary format. `nil` if `data` is encoded in a proprietary
     format.
     - Parameter data: The undecoded data. For Unicode, each unicode
     character is represented by 4 Hex character codes. The letter “A” would
     be represented by 0041 hex, while the “Katakana letter A” would be
     represented by 30A2 hex. For ASCII, each ASCII character is represented
     by 2 Hex character codes. The letter “A” would be represented by 41
     hex, while the Latin capital letter thorn “Þ” would be represented by
     DE hex. The “Katakana letter A” cannot be represented by 2 Hex
     character codes.
     - Parameter translationCode: Translation code for text body.
     `U` = Unicode, `A` = ASCII, `1` through `16` = subset and part number
     of ISO 8859, `Pxyz` = Proprietary (user defined).
    
     - SeeAlso: ``text(_:identifier:)``
     */
    case multiLanguageText(source: Talker, text: String?, data: Data, translationCode: String)

    /**
     8.3.87 TXT – Text transmission
    
     For the transmission of short text messages. Longer text messages may
     be transmitted by using multiple sentences.
    
     - Parameter message: Text message
     - Parameter identifier: Text identifier. The text identifier is a
     number, 01 to 99, used to identify different text messages.
     */
    case text(_ message: String, identifier: Int?)

    /**
     8.3.88 UID – User identification code transmission
    
     This sentence allows a user to send an identification message to a
     system.
    
     - Parameter code1: User identification code 1
     - Parameter code2: User identification code 2 (optional). User
     identification code 2 is optional and allows further identification of
     the user or his project.
     - Note: User identification code UIC may consist of up to 20
     alpha-numerical characters (A-Z, a-z, and 0-9). UIC will be used by the
     receiving system to identify the user and check the validity of the
     request. UIC might be recorded for accounting purposes. Field equipment
     needs to have means to input both UICs (e.g. input dialog).
     */
    case userIdentification(code1: String, code2: String?)

    /**
     8.3.89 VBW – Dual ground/water speed
    
     Water-referenced and ground-referenced speed data.
    
     - Parameter water: Longitudinal and transverse water speed, knots
     - Parameter waterValid: Water speed data validity
     - Parameter ground: Longitudinal and transverse ground speed, knots
     - Parameter groundValid: Ground speed data validity
     - Parameter sternTransverseWater: Stern transverse water speed, knots
     - Parameter sternTransverseWaterValid: Stern transverse water speed
     validity
     - Parameter sternTransverseGround: Stern transverse ground speed, knots
     - Parameter sternTransverseGroundValid: Stern transverse ground speed
     validity
     */
    case speedData(
      water: SpeedVector,
      waterValid: Bool,
      ground: SpeedVector,
      groundValid: Bool,
      sternTransverseWater: Measurement<UnitSpeed>,
      sternTransverseWaterValid: Bool,
      sternTransverseGround: Measurement<UnitSpeed>,
      sternTransverseGroundValid: Bool
    )

    /**
     8.3.90 VDM – AIS VHF data-link message
    
     This sentence is used to transfer the entire content of a received AIS
     message packet, as defined in ITU-R M.1371 and as received on the
     VHF Data Link (VDL), using the “six-bit” field type. The structure
     provides for the transfer of long binary messages by using multiple
     sentences.
    
     Data messages should be transmitted in as few sentences as possible.
     When a data message can be accommodated in a single sentence, then it
     shall not be split.
    
     - Parameter message: Encapsulated ITU-R M.1371 radio message
     - Parameter channel: AIS channel. This channel indication is relative
     to the operating conditions of the AIS unit when the packet is
     received. This should be a `nil` field when the channel identification
     is not provided. The VHF channel numbers for channels ``AIS/Channel/A``
     and ``AIS/Channel/B`` are obtained by using a “query” (see 7.3.5) of
     the AIS unit for an `ACA` sentence.
     - SeeAlso: ``AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    case VDLMessage(_ message: Data, channel: AIS.Channel?)

    /**
     8.3.91 VDO – AIS VHF data-link own-vessel report
    
     This sentence is used to transfer the entire content of an AIS unit’s
     broadcast message packet, as defined in ITU-R M.1371 and as sent out by
     the AIS unit over the VHF data link (VDL) using the “six-bit” field
     type. The sentence uses the same structure as the `VDM` sentence
     formatter.
    
     - Parameter message: Encapsulated ITU-R M.1371 radio message
     - Parameter channel: AIS channel. This channel indication is relative
     to the operating conditions of the AIS unit when the packet is
     received. This should be a `nil` field when the channel identification
     is not provided. The VHF channel numbers for channels ``AIS/Channel/A``
     and ``AIS/Channel/B`` are obtained by using a “query” (see 7.3.5) of
     the AIS unit for an `ACA` sentence.
     - SeeAlso: ``VDLMessage(_:channel:)``
     - SeeAlso: ``AISChannelAssignment(sequenceNumber:northeastCorner:southwestCorner:transitionZoneSize:channelA:channelABandwidth:channelB:channelBBandwidth:txRxMode:powerLevel:source:inUse:inUseChanged:)``
     */
    case VDLOwnshipReport(_ message: Data, channel: AIS.Channel?)

    /**
     8.3.92 VDR – Set and drift
    
     The direction towards which a current flows (set) and speed (drift) of
     a current.
    
     - Parameter setTrue: Direction, degrees true
     - Parameter setMagnetic: Direction, degrees magnetic
     - Parameter drift: Current speed, knots
     */
    case currentSetDrift(setTrue: Bearing, setMagnetic: Bearing, drift: Measurement<UnitSpeed>)

    /**
     8.3.93 VER – Version
    
     This sentence is used to provide identification and version information
     about a device. This sentence is produced as a reply to a query sentence.
    
     In order to meet the 79-character requirement, a “multi-sentence
     message” may be needed to convey all the data fields.
    
     For example, an equipment may output the `VER` sentence autonomously
     upon power-up.
    
     - Parameter type: Device type. The device type is used to identify the
     manufactured purpose of the device. Choice of the device type
     identifier is based upon the designed purpose of the device. It is set
     into the equipment based upon the primary design of the device and
     remains constant even if the user defined talker identifier feature is
     used.
     - Parameter vendorID: Vendor identification (Example: either the
     NMEA 0183, 3-character “Manufacturer’s Mnemonic Code” or NMEA 2000,
     5-digit “Numeric Manufacturer’s Code”, 5 characters maximum.).
     - Parameter uniqueID: The unique identifier is used for system level
     identification of a station, 15 characters maximum.
     - Parameter serialNumber: The manufacturer’s serial number for the
     unit. Note, this “internal” manufacturer’s serial number may or may not
     match the physical serial number of the device.
     - Parameter modelCode: Model code (product code)
     - Parameter softwareRevision: Software revision
     - Parameter hardwareRevision: Hardware revision
     */
    case version(
      type: String,
      vendorID: String,
      uniqueID: String,
      serialNumber: String,
      modelCode: String,
      softwareRevision: String,
      hardwareRevision: String
    )

    /**
     8.3.94 VHW – Water speed and heading
    
     The compass heading to which the vessel points and the speed of the
     vessel relative to the water.
    
     - Parameter true: Heading, degrees true
     - Parameter magnetic: Heading, degrees magnetic
     - Parameter speedKnots: Speed, knots
     - Parameter speedKph: Speed, km/h
     */
    case waterSpeedHeading(
      true: Bearing,
      magnetic: Bearing,
      speedKnots: Measurement<UnitSpeed>,
      speedKph: Measurement<UnitSpeed>
    )

    /**
     8.3.95 VLW – Dual ground/water distance
    
     The distance travelled, relative to the water and over the ground.
    
     - Parameter waterCumulative: Total cumulative water distance, nautical miles
     - Parameter waterSinceReset: Water distance since reset, nautical miles
     - Parameter groundCumulative: Total cumulative ground distance, nautical miles
     - Parameter groundSinceReset: Ground distance since reset, nautical miles
     */
    case distanceData(
      waterCumulative: Measurement<UnitLength>,
      waterSinceReset: Measurement<UnitLength>,
      groundCumulative: Measurement<UnitLength>,
      groundSinceReset: Measurement<UnitLength>
    )

    /**
     8.3.96 VPW – Speed measured parallel to wind
    
     The component of the vessel's velocity vector parallel to the direction
     of the true wind direction. Sometimes called "speed made good to
     windward" or "velocity made good to windward".
    
     - Parameter knots: Speed, knots, "-" = downwind
     - Parameter mps: Speed, m/s, "-" = downwind
     */
    case speedParallelToWind(knots: Measurement<UnitSpeed>, mps: Measurement<UnitSpeed>)

    /**
     8.3.97 VSD – AIS voyage static data
    
     This sentence is used to enter information about a ship’s transit that
     remains relatively static during the voyage. However, the information
     often changes from voyage to voyage. The parameters in this sentence
     support a number of the ITU-R M.1371 messages.
    
     - Parameter shipType: Type of ship and cargo category. A `nil` field
     indicates that this is unchanged.
     - Parameter maxDraft: Maximum present static draught, 0 to 25,5 m. A
     `nil` field indicates that this is unchanged.
     - Parameter soulsOnboard: Current number of persons on-board including
     crew. Valid range is 0 to 8 191. The value 8 191 = 8 191 or more people.
     A `nil` field indicates that this is unchanged.
     - Parameter destination: Destination name. A `nil` field indicates that this is unchanged.
     - Parameter destinationETA: Estimated UTC of arrival at destination.
     `nil` values for any date component field indicate that that field is
     unchanged.
     - Parameter navStatus: Navigational status. A `nil` field indicates
     that this is unchanged.
     - Parameter regionalFlags: Definition of values 1 to 15 provided by a
     competent regional authority. Value should be set to zero (0), if
     not used for any regional application. Regional applications should not
     use zero. A `nil` field indicates that this is unchanged (ref.
     ITU-R M.1371, Message 1, reserved for regional applications parameter).
     */
    case AISVoyageData(
      shipType: AISLongRange.ShipType?,
      maxDraft: AIS.Availability<Measurement<UnitLength>>?,
      soulsOnboard: AIS.Availability<Int>?,
      destination: AIS.Availability<String>?,
      destinationETA: AIS.DateAvailability,
      navStatus: AIS.NavigationalStatus?,
      regionalFlags: Int?
    )

    /**
     8.3.98 VTG – Course over ground and ground speed
    
     The actual course and speed relative to the ground.
    
     - Parameter courseTrue: Course over ground, degrees true
     - Parameter couseMagnetic: Course over ground, degrees magnetic
     - Parameter speedKnots: Speed over ground, knots
     - Parameter speedKph: Speed over ground, km/h
     - Parameter mode: Mode indicator. The mode indicator provides status
     information about the operation of the source device (such as
     positioning systems, velocity sensors, etc.) generating the sentence,
     and the validity of data being provided.
     - Note: The speed over the ground should always be non-negative.
     */
    case groundSpeedCourse(
      courseTrue: Bearing,
      courseMagnetic: Bearing,
      speedKnots: Measurement<UnitSpeed>,
      speedKph: Measurement<UnitSpeed>,
      mode: Navigation.Mode
    )

    /**
     8.3.99 WAT – Water level detection
    
     This sentence provides detection status of water leakage and bilge
     water level, with monitoring location data.
    
     - Parameter messageType: Message type
     - Parameter time: Time when this status/message was valid
     - Parameter systemType: Type of water alarm system
     - Parameter location1: First location indicator characters showing
     detection location. This field is two characters. The content of this
     field is not defined by this standard, but the two location fields
     should uniquely define the source for the alarm.
     - Parameter location2: Second location indicator character showing
     detection location. This field is two characters.The content of this
     field is not defined by this standard, but the two location fields
     should uniquely define the source for the alarm.
     - Parameter number: Detection point number or detection point count.
     When the message type field is ``Doors/MessageType/event`` this field
     identifies the high-water-level detection point. When the message type
     field is ``Doors/MessageType/section`` this field contains the number
     of the water leakage detection points. When the message type field is
     ``Doors/MessageType/fault`` this field is a `nil` field.
     - Parameter alarmCondition: Alarm condition. When the message type
     field is ``Doors/MessageType/section`` or ``Doors/MessageType/fault``
     this field should be a `nil` field.
     - Parameter isOverriden: If `true`, override mode (water allowed in
     space); if `false`, normal mode (water not allowed in space)
     - Parameter description: Descriptive text/level detector tag. If a
     level detector identifier is string type, it is possible to use this
     field instead of above level detector location fields. Maximum number
     of characters will be limited by maximum sentence length and length of
     other fields.
     */
    case waterLevel(
      messageType: Doors.MessageType,
      time: Date?,
      systemType: WaterSensor.SystemType,
      location1: String?,
      location2: String?,
      number: Int?,
      alarmCondition: WaterSensor.Status?,
      isOverriden: Bool?,
      description: String?
    )

    /**
     8.3.100 WCV – Waypoint closure velocity
    
     The component of the velocity vector in the direction of the waypoint,
     from present position. Sometimes called "speed made good" or "velocity
     made good".
    
     - Parameter closure: Velocity component, knots
     - Parameter identifier: Waypoint identifier
     - Parameter mode: Mode indicator
     */
    case waypointClosure(
      _ closure: Measurement<UnitSpeed>,
      identifier: String,
      mode: Navigation.Mode
    )

    /**
     8.3.101 WNC – Distance waypoint to waypoint
    
     Distance between two specified waypoints.
    
     - Parameter distanceNM: Distance, nautical miles
     - Parameter distanceKM: Distance, km
     - Parameter to: TO waypoint identifier
     - Parameter from: FROM waypoint identifier
     */
    case distanceWaypointToWaypoint(
      distanceNM: Measurement<UnitLength>,
      distanceKM: Measurement<UnitLength>,
      to: String,
      from: String
    )

    /**
     8.3.102 WPL – Waypoint location
    
     Latitude and longitude of specified waypoint.
    
     - Parameter location: Waypoint latitude and longitude
     - Parameter identifier: Waypoint identifier
     */
    case waypointLocation(_ location: Position, identifier: String)

    /**
     8.3.103 XDR – Transducer measurements
    
     Measurement data from transducers that measure physical quantities such
     as temperature, force, pressure, frequency, angular or linear
     displacement, etc. Data from a variable number of transducers measuring
     the same or different quantities can be mixed in the same sentence.
     This sentence is designed for use by integrated systems as well as
     transducers that may be connected in a "chain" where each transducer
     receives the sentence as an input and adds on its own data fields
     before retransmitting the sentence.
    
     - Parameter measurements: The transducer measurements.
     */
    case transducerMeasurements(_ measurements: [Transducer.Value])

    /**
     8.3.104 XTE – Cross-track error, measured
    
     Magnitude of the position error perpendicular to the intended track
     line and the direction to steer to return to track.
    
     - Parameter error: Cross-track error (left is negative)
     - Parameter mode: Mode indicator
     - Parameter LORANC_blinkSNRFlag: LORAN – C blink or SNR warning
     - Parameter LORANC_cycleLockWarningFlag: Loran-C cycle lock warning flag
     */
    case crossTrackError(
      _ error: Measurement<UnitLength>,
      mode: Navigation.Mode,
      LORANC_blinkSNRFlag: Bool,
      LORANC_cycleLockWarningFlag: Bool
    )

    /**
     8.3.105 XTR – Cross-track error, dead reckoning
    
     Magnitude of the dead reckoned position error perpendicular to the
     intended track line and the direction to steer to return to track.
    
     - Parameter error: Cross-track error (left is negative)
     */
    case crossTrackErrorDR(_ error: Measurement<UnitLength>)

    /**
     8.3.106 ZDA – Time and date
    
     UTC, day, month, year and local time zone.
    
     - Parameter date: Date, UTC
     - Parameter timeZone: Local timezone (current offset from GMT only)
     */
    case dateTime(_ date: Date, timeZone: TimeZone)

    /**
     8.3.107 ZDL – Time and distance to variable point
    
     Time and distance to a point that might not be fixed. The point is
     generally not a specific geographic point but may vary continuously,
     and is most often determined by calculation (the recommended turning
     point for sailboats for optimum sailing to a destination, the
     wheel-over point for vessels making turns, a predicted collision point,
     etc.).
    
     - Parameter time: Time to point, 00 h to 99 h
     - Parameter distance: Distance to point, nautical miles
     - Parameter type: Type of point
     */
    case timeDistanceToVariablePoint(
      time: Duration,
      distance: Measurement<UnitLength>,
      type: Navigation.VariablePoint
    )

    /**
     8.3.108 ZFO – UTC and time from origin waypoint
    
     UTC and elapsed time from origin waypoint.
    
     - Parameter observation: UTC of observation
     - Parameter elapsedTime: Elapsed time, hh = 00 to 99
     - Parameter originID: Origin waypoint ID
     */
    case timeFromOrigin(observation: Date, elapsedTime: Duration, originID: String)

    /**
     8.3.109 ZTG – UTC and time to destination waypoint
    
     UTC and predicted time-to-go to destination waypoint.
    
     - Parameter observation: UTC of observation
     - Parameter elapsedTime: Elapsed time, hh = 00 to 99
     - Parameter destinationID: Destination waypoint ID
     */
    case timeToDestination(observation: Date, timeToGo: Duration, destinationID: String)
  }
}
