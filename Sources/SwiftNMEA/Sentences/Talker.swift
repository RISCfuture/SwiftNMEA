/// Possible values for the Talker field.
public enum Talker: RawRepresentable, Sendable, Codable, Equatable, Hashable {
    public typealias RawValue = String

    /// Heading/track controller (autopilot) (general)
    case autopilotGeneral

    /// Heading/track controller (autopilot) (magnetic)
    case autopilotMagnetic

    /// Automatic identification system
    case automaticID

    /// Bilge system
    case bilgeSystem

    /// Bridge navigational watch alarm system
    case navWatchAlarm

    /// Communications: digital selective calling (DSC)
    case commDSC

    /// Communications: data receiver
    case commDataReceiver

    /// Communications: satellite
    case commSatellite

    /// Communications: radio-telephone (MF/HF)
    case commMF_HF

    /// Communications: radio-telephone (VHF)
    case commVHF

    /// Communications: scanning receiver
    case commScanner

    /// Direction finder
    case directionFinder

    /// Duplex repeater station
    case duplexRepeater

    /// Electronic chart system (ECS)
    case ECS

    /// Electronic chart display and information system (ECDIS)
    case ECDIS

    /// Emergency position indicating radio beacon (EPIRB)
    case EPIRB

    /// Engine room monitoring system
    case engineRoomMonitor

    /// Fire door controller/monitoring system
    case fireDoorController

    /// Fire extinguisher system
    case fireExtinguishing

    /// Fire detection system
    case fireDetection

    /// Fire sprinkler system
    case fireSprinkler

    /// Galileo positioning system
    case galileo

    /// Global positioning system (GPS)
    case GPS

    /// GLONASS positioning system (ГЛОНАСС)
    case GLONASS

    /// Global navigation satellite system (GNSS) or combined GNSS sources
    case GNSS

    /// BeiDou positioning systemn (北斗卫星导航系统)
    case beidou

    /// Quasi-Zenith Satellite System (みちびき)
    case QZSS

    /// Heading sensor: compass, magnetic
    case magneticCompass

    /// Heading sensor: gyro, north seeking
    case gyroCompassSlaved

    /// Heading sensor: fluxgate
    case fluxgate

    /// Heading sensor: gyro, non-north seeking
    case gyroCompass

    /// Hull door controller/monitoring system
    case hullDoorController

    /// Hull stress monitoring
    case hullStressMonitoring

    /// Integrated instrumentation
    case integratedInstrumentation

    /// Integrated navigation
    case integratedNavigation

    /// LORAN-C
    case LORAN

    /// Navigation light controller
    case navLightController

    /// Radar and/or radar plotting
    case radar

    /// Propulsion machinery including remote control
    case propulsion

    /// Sounder, depth
    case depthSounder

    /// Steering gear/steering engine
    case steering

    /// Electronic positioning system, other/general
    case electronicPositioningSystem

    /// Sounder, scanning
    case scanningSounder

    /// Turn rate indicator
    case turnRateIndicator

    /// Microprocessor controller
    case microprocessor

    /// Velocity sensors: Doppler, other/general
    case dopplerVelocity

    /// Velocity sensors: speed log, water, magnetic
    case magneticSpeedLog

    /// Velocity sensors: speed log, water, mechanical
    case mechanicalSpeedLog

    /// Voyage data recorder
    case voyageRecorder

    /// Watertight door controller/monitoring system
    case watertightDoorController

    /// Water level detection system
    case waterLevelDetection

    /// Transducer
    case transducer

    /// Timekeeper, time/date: atomic clock
    case atomicClock

    /// Timekeeper, time/date: chronometer
    case chronometer

    /// Timekeeper, time/date: quartz
    case quartzClock

    /// Timekeeper, time/date: radio update
    case radioTime

    /// Weather instrument
    case weatherInstrument

    /**
     User configured talker identifier.

     The U# talker identifier does not convey the nature of the device
     transmitting the sentence, and should not be “fixed” into a unit at
     manufacture. This is intended for special purpose applications. The U#
     talker identifier indicates that the devices talker identifier has been
     changed through external control.

     - Parameter number: Talker identifier
     */
    case userConfigured(number: Int)

    /// Unknown talker ID
    case unknown(_ ID: String)

    public var rawValue: String {
        switch self {
            case .autopilotGeneral: return "AG"
            case .autopilotMagnetic: return "AM"
            case .automaticID: return "AI"
            case .bilgeSystem: return "BI"
            case .navWatchAlarm: return "BN"
            case .commDSC: return "CD"
            case .commDataReceiver: return "CR"
            case .commSatellite: return "CS"
            case .commMF_HF: return "CT"
            case .commVHF: return "CV"
            case .commScanner: return "CX"
            case .directionFinder: return "DF"
            case .duplexRepeater: return "DU"
            case .ECS: return "EC"
            case .ECDIS: return "EI"
            case .EPIRB: return "EP"
            case .engineRoomMonitor: return "ER"
            case .fireDoorController: return "FD"
            case .fireExtinguishing: return "FE"
            case .fireDetection: return "FR"
            case .fireSprinkler: return "FS"
            case .galileo: return "GA"
            case .GPS: return "GP"
            case .GLONASS: return "GL"
            case .GNSS: return "GS"
            case .magneticCompass: return "HC"
            case .gyroCompassSlaved: return "HE"
            case .fluxgate: return "HF"
            case .gyroCompass: return "HN"
            case .hullDoorController: return "HD"
            case .hullStressMonitoring: return "HS"
            case .integratedInstrumentation: return "II"
            case .integratedNavigation: return "IN"
            case .LORAN: return "LC"
            case .navLightController: return "NL"
            case .radar: return "RA"
            case .propulsion: return "RC"
            case .depthSounder: return "SD"
            case .steering: return "SG"
            case .electronicPositioningSystem: return "SN"
            case .scanningSounder: return "SS"
            case .turnRateIndicator: return "TI"
            case .microprocessor: return "UP"
            case .dopplerVelocity: return "VD"
            case .magneticSpeedLog: return "VM"
            case .mechanicalSpeedLog: return "VW"
            case .voyageRecorder: return "VR"
            case .watertightDoorController: return "WD"
            case .waterLevelDetection: return "WL"
            case .transducer: return "YX"
            case .atomicClock: return "ZA"
            case .chronometer: return "ZC"
            case .quartzClock: return "ZQ"
            case .radioTime: return "ZV"
            case .weatherInstrument: return "WI"
            case let .userConfigured(number): return "U\(number)"
            case .beidou: return "GB"
            case .QZSS: return "GQ"
            case let .unknown(ID): return ID
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
            case "AG": self = .autopilotGeneral
            case "AM": self = .autopilotMagnetic
            case "AI": self = .automaticID
            case "BI": self = .bilgeSystem
            case "BN": self = .navWatchAlarm
            case "CD": self = .commDSC
            case "CR": self = .commDataReceiver
            case "CS": self = .commSatellite
            case "CT": self = .commMF_HF
            case "CV": self = .commVHF
            case "CX": self = .commScanner
            case "DF": self = .directionFinder
            case "DU": self = .duplexRepeater
            case "EC": self = .ECS
            case "EI": self = .ECDIS
            case "EP": self = .EPIRB
            case "ER": self = .engineRoomMonitor
            case "FD": self = .fireDoorController
            case "FE": self = .fireExtinguishing
            case "FR": self = .fireDetection
            case "FS": self = .fireSprinkler
            case "GA": self = .galileo
            case "GB": self = .beidou
            case "GP": self = .GPS
            case "GL": self = .GLONASS
            case "GN", "GS": self = .GNSS
            case "GQ": self = .QZSS
            case "HC": self = .magneticCompass
            case "HE": self = .gyroCompassSlaved
            case "HF": self = .fluxgate
            case "HN": self = .gyroCompass
            case "HD": self = .hullDoorController
            case "HS": self = .hullStressMonitoring
            case "II": self = .integratedInstrumentation
            case "IN": self = .integratedNavigation
            case "LC": self = .LORAN
            case "NL": self = .navLightController
            case "RA": self = .radar
            case "RC": self = .propulsion
            case "SD": self = .depthSounder
            case "SG": self = .steering
            case "SN": self = .electronicPositioningSystem
            case "SS": self = .scanningSounder
            case "TI": self = .turnRateIndicator
            case "UP": self = .microprocessor
            case "VD": self = .dopplerVelocity
            case "VM": self = .magneticSpeedLog
            case "VW": self = .mechanicalSpeedLog
            case "VR": self = .voyageRecorder
            case "WD": self = .watertightDoorController
            case "WL": self = .waterLevelDetection
            case "YX": self = .transducer
            case "ZA": self = .atomicClock
            case "ZC": self = .chronometer
            case "ZQ": self = .quartzClock
            case "ZV": self = .radioTime
            case "WI": self = .weatherInstrument
            case "U0": self = .userConfigured(number: 0)
            case "U1": self = .userConfigured(number: 1)
            case "U2": self = .userConfigured(number: 2)
            case "U3": self = .userConfigured(number: 3)
            case "U4": self = .userConfigured(number: 4)
            case "U5": self = .userConfigured(number: 5)
            case "U6": self = .userConfigured(number: 6)
            case "U7": self = .userConfigured(number: 7)
            case "U8": self = .userConfigured(number: 8)
            case "U9": self = .userConfigured(number: 9)
            default: self = .unknown(rawValue)
        }
    }
}
