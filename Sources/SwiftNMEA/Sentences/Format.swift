/**
 Approved sentence format types. Other sentence format types are captured using
 ``unknown(_:)``.

 - SeeAlso: ``Message/Payload-swift.enum``
 */
public enum Format: RawRepresentable, Sendable, Codable, Equatable, Hashable {
    public typealias RawValue = String

    case waypointArrivalAlarm
    case AISBroadcastAcknowledgement
    case AISBinaryMessage
    case AISChannelAssignment
    case alarmAcknowledgement
    case AISChannelInformationSource
    case AISInterrogationRequest
    case detailAlarmAcknowledgement
    case detailAlarm
    case alarmState
    case autopilotSentenceB
    case AISBroadcastBinaryMessage
    case bearingDistanceToWaypointDR
    case bearingOriginToDest
    case bearingDistanceToWaypointGC
    case bearingDistanceToWaypointRL
    case bearingWaypointToWaypoint
    case navaidMessageBroadcastRates
    case currentWaterLayer
    case depthBelowTransducer
    case displayDimmingControl
    case doorStatus
    case depth
    case DSC
    case DSE
    case datumReference
    case engineTelegraph
    case event
    case fireDetection
    case frequencySetInfo
    case GNSSFaultDetection
    case genericBinary
    case GNSSAccuracyIntegrity
    case GPSFix
    case geoPosition
    case GNSSFix
    case GNSSRangeResiduals
    case GNSS_DOP
    case GNSSPseudorangeNoise
    case GNSSSatellitesInView
    case heartbeat
    case heading
    case trueHeading
    case headingMonitorReceive
    case headingMonitorSet
    case headingSteeringCommand
    case hullStress
    case headingControlCommand
    case headingControlData
    case AISLongRangeReply1
    case AISLongRangeReply2
    case AISLongRangeReply3
    case AISLongRangeFunction
    case AISLongRangeInterrogation
    case broadcastCommandMessage
    case MSKReceiverInterface
    case MSKReceiverSignalStatus
    case waterTemperature
    case windDirectionSpeed
    case windAngleSpeed
    case negativeAcknowledgement
    case NAVTEXReceiverMask
    case NAVTEXMessage
    case ownshipData
    case positionDimensions
    case propulsionRemoteControl
    case LORANCMinimumData
    case destinationMinimumData
    case GNSSMinimumData
    case rudderOrder
    case rateOfTurn
    case revolutions
    case rudderSensorAngle
    case radarSystemData
    case route
    case scanningFrequencies
    case AISShipStaticData
    case talkerID
    case trueHeadingMode
    case targetLabels
    case targetPosition
    case thrusterControl
    case thrusterResponse
    case trackedTargets
    case trackedTarget
    case multiLanguageText
    case text
    case userIdentification
    case speedData
    case VDLMessage
    case VDLOwnshipReport
    case currentSetDrift
    case version
    case waterSpeedHeading
    case distanceData
    case speedParallelToWind
    case AISVoyageData
    case groundSpeedCourse
    case waterLevel
    case waypointClosure
    case distanceWaypointToWaypoint
    case waypointLocation
    case transducerMeasurements
    case crossTrackError
    case crossTrackErrorDR
    case dateTime
    case timeDistanceToVariablePoint
    case timeFromOrigin
    case timeToDestination
    case unknown(_ ID: String)

    public var rawValue: RawValue {
        switch self {
            case .waypointArrivalAlarm: "AAM"
            case .AISBroadcastAcknowledgement: "ABK"
            case .AISBinaryMessage: "ABM"
            case .AISChannelAssignment: "ACA"
            case .alarmAcknowledgement: "ACK"
            case .AISChannelInformationSource: "ACS"
            case .AISInterrogationRequest: "AIR"
            case .detailAlarmAcknowledgement: "AKD"
            case .detailAlarm: "ALA"
            case .alarmState: "ALR"
            case .autopilotSentenceB: "APB"
            case .AISBroadcastBinaryMessage: "BBM"
            case .bearingDistanceToWaypointDR: "BEC"
            case .bearingOriginToDest: "BOD"
            case .bearingDistanceToWaypointGC: "BWC"
            case .bearingDistanceToWaypointRL: "BWR"
            case .bearingWaypointToWaypoint: "BWW"
            case .navaidMessageBroadcastRates: "CBR"
            case .currentWaterLayer: "CUR"
            case .depthBelowTransducer: "DBT"
            case .displayDimmingControl: "DDC"
            case .doorStatus: "DOR"
            case .depth: "DPT"
            case .DSC: "DSC"
            case .DSE: "DSE"
            case .datumReference: "DTM"
            case .engineTelegraph: "ETL"
            case .event: "EVE"
            case .fireDetection: "FIR"
            case .frequencySetInfo: "FSI"
            case .GNSSFaultDetection: "GBS"
            case .genericBinary: "GEN"
            case .GNSSAccuracyIntegrity: "GFA"
            case .GPSFix: "GGA"
            case .geoPosition: "GLL"
            case .GNSSFix: "GNS"
            case .GNSSRangeResiduals: "GRS"
            case .GNSS_DOP: "GSA"
            case .GNSSPseudorangeNoise: "GST"
            case .GNSSSatellitesInView: "GSV"
            case .heartbeat: "HBT"
            case .heading: "HDG"
            case .trueHeading: "HDT"
            case .headingMonitorReceive: "HMR"
            case .headingMonitorSet: "HMS"
            case .headingSteeringCommand: "HSC"
            case .hullStress: "HSS"
            case .headingControlCommand: "HTC"
            case .headingControlData: "HTD"
            case .AISLongRangeReply1: "LR1"
            case .AISLongRangeReply2: "LR2"
            case .AISLongRangeReply3: "LR3"
            case .AISLongRangeFunction: "LRF"
            case .AISLongRangeInterrogation: "LRI"
            case .broadcastCommandMessage: "MEB"
            case .MSKReceiverInterface: "MSK"
            case .MSKReceiverSignalStatus: "MSS"
            case .waterTemperature: "MTW"
            case .windDirectionSpeed: "MWD"
            case .windAngleSpeed: "MWV"
            case .negativeAcknowledgement: "NAK"
            case .NAVTEXReceiverMask: "NRM"
            case .NAVTEXMessage: "NRX"
            case .ownshipData: "OSD"
            case .positionDimensions: "POS"
            case .propulsionRemoteControl: "PRC"
            case .LORANCMinimumData: "RMA"
            case .destinationMinimumData: "RMB"
            case .GNSSMinimumData: "RMC"
            case .rudderOrder: "ROR"
            case .rateOfTurn: "ROT"
            case .revolutions: "RPM"
            case .rudderSensorAngle: "RSA"
            case .radarSystemData: "RSD"
            case .route: "RTE"
            case .scanningFrequencies: "SFI"
            case .AISShipStaticData: "SSD"
            case .talkerID: "STN"
            case .trueHeadingMode: "THS"
            case .targetLabels: "TLB"
            case .targetPosition: "TLL"
            case .thrusterControl: "TRC"
            case .thrusterResponse: "TRD"
            case .trackedTargets: "TTD"
            case .trackedTarget: "TTM"
            case .multiLanguageText: "TUT"
            case .text: "TXT"
            case .userIdentification: "UID"
            case .speedData: "VBW"
            case .VDLMessage: "VDM"
            case .VDLOwnshipReport: "VDO"
            case .currentSetDrift: "VDR"
            case .version: "VER"
            case .waterSpeedHeading: "VHW"
            case .distanceData: "VLW"
            case .speedParallelToWind: "VPW"
            case .AISVoyageData: "VSD"
            case .groundSpeedCourse: "VTG"
            case .waterLevel: "WAT"
            case .waypointClosure: "WCV"
            case .distanceWaypointToWaypoint: "WNC"
            case .waypointLocation: "WPL"
            case .transducerMeasurements: "XDR"
            case .crossTrackError: "XTE"
            case .crossTrackErrorDR: "XTR"
            case .dateTime: "ZDA"
            case .timeDistanceToVariablePoint: "ZDL"
            case .timeFromOrigin: "ZFO"
            case .timeToDestination: "ZTG"
            case let .unknown(ID): ID
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
            case "AAM": self = .waypointArrivalAlarm
            case "ABK": self = .AISBroadcastAcknowledgement
            case "ABM": self = .AISBinaryMessage
            case "ACA": self = .AISChannelAssignment
            case "ACK": self = .alarmAcknowledgement
            case "ACS": self = .AISChannelInformationSource
            case "AIR": self = .AISInterrogationRequest
            case "AKD": self = .detailAlarmAcknowledgement
            case "ALA": self = .detailAlarm
            case "ALR": self = .alarmState
            case "APB": self = .autopilotSentenceB
            case "BBM": self = .AISBroadcastBinaryMessage
            case "BEC": self = .bearingDistanceToWaypointDR
            case "BOD": self = .bearingOriginToDest
            case "BWC": self = .bearingDistanceToWaypointGC
            case "BWR": self = .bearingDistanceToWaypointRL
            case "BWW": self = .bearingWaypointToWaypoint
            case "CBR": self = .navaidMessageBroadcastRates
            case "CUR": self = .currentWaterLayer
            case "DBT": self = .depthBelowTransducer
            case "DDC": self = .displayDimmingControl
            case "DOR": self = .doorStatus
            case "DPT": self = .depth
            case "DSC": self = .DSC
            case "DSE": self = .DSE
            case "DTM": self = .datumReference
            case "ETL": self = .engineTelegraph
            case "EVE": self = .event
            case "FIR": self = .fireDetection
            case "FSI": self = .frequencySetInfo
            case "GBS": self = .GNSSFaultDetection
            case "GEN": self = .genericBinary
            case "GFA": self = .GNSSAccuracyIntegrity
            case "GGA": self = .GPSFix
            case "GLL": self = .geoPosition
            case "GNS": self = .GNSSFix
            case "GRS": self = .GNSSRangeResiduals
            case "GSA": self = .GNSS_DOP
            case "GST": self = .GNSSPseudorangeNoise
            case "GSV": self = .GNSSSatellitesInView
            case "HBT": self = .heartbeat
            case "HDG": self = .heading
            case "HDT": self = .trueHeading
            case "HMR": self = .headingMonitorReceive
            case "HMS": self = .headingMonitorSet
            case "HSC": self = .headingSteeringCommand
            case "HSS": self = .hullStress
            case "HTC": self = .headingControlCommand
            case "HTD": self = .headingControlData
            case "LR1": self = .AISLongRangeReply1
            case "LR2": self = .AISLongRangeReply2
            case "LR3": self = .AISLongRangeReply3
            case "LRF": self = .AISLongRangeFunction
            case "LRI": self = .AISLongRangeInterrogation
            case "MEB": self = .broadcastCommandMessage
            case "MSK": self = .MSKReceiverInterface
            case "MSS": self = .MSKReceiverSignalStatus
            case "MTW": self = .waterTemperature
            case "MWD": self = .windDirectionSpeed
            case "MWV": self = .windAngleSpeed
            case "NAK": self = .negativeAcknowledgement
            case "NRM": self = .NAVTEXReceiverMask
            case "NRX": self = .NAVTEXMessage
            case "OSD": self = .ownshipData
            case "POS": self = .positionDimensions
            case "PRC": self = .propulsionRemoteControl
            case "RMA": self = .LORANCMinimumData
            case "RMB": self = .destinationMinimumData
            case "RMC": self = .GNSSMinimumData
            case "ROR": self = .rudderOrder
            case "ROT": self = .rateOfTurn
            case "RPM": self = .revolutions
            case "RSA": self = .rudderSensorAngle
            case "RSD": self = .radarSystemData
            case "RTE": self = .route
            case "SFI": self = .scanningFrequencies
            case "SSD": self = .AISShipStaticData
            case "STN": self = .talkerID
            case "THS": self = .trueHeadingMode
            case "TLB": self = .targetLabels
            case "TLL": self = .targetPosition
            case "TRC": self = .thrusterControl
            case "TRD": self = .thrusterResponse
            case "TTD": self = .trackedTargets
            case "TTM": self = .trackedTarget
            case "TUT": self = .multiLanguageText
            case "TXT": self = .text
            case "UID": self = .userIdentification
            case "VBW": self = .speedData
            case "VDM": self = .VDLMessage
            case "VDO": self = .VDLOwnshipReport
            case "VDR": self = .currentSetDrift
            case "VER": self = .version
            case "VHW": self = .waterSpeedHeading
            case "VLW": self = .distanceData
            case "VPW": self = .speedParallelToWind
            case "VSD": self = .AISVoyageData
            case "VTG": self = .groundSpeedCourse
            case "WAT": self = .waterLevel
            case "WCV": self = .waypointClosure
            case "WNC": self = .distanceWaypointToWaypoint
            case "WPL": self = .waypointLocation
            case "XDR": self = .transducerMeasurements
            case "XTE": self = .crossTrackError
            case "XTR": self = .crossTrackErrorDR
            case "ZDA": self = .dateTime
            case "ZDL": self = .timeDistanceToVariablePoint
            case "ZFO": self = .timeFromOrigin
            case "ZTG": self = .timeToDestination
            default: self = .unknown(rawValue)
        }
    }
}
