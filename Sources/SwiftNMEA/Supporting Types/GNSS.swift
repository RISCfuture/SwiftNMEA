import Foundation

// swiftlint:disable:next missing_docs
public struct GNSS {
  private init() {}

  /// The GNSS System ID (per IEC 61162-1 ed.6.0) identified by a talker, used
  /// by sentences (e.g. GSV) that convey the constellation via the talker
  /// rather than an explicit System ID field. Returns `nil` for non-GNSS
  /// talkers and the combined-GNSS talker (GN), whose system is ambiguous.
  static func systemID(forTalker talker: Talker) -> Int? {
    switch talker {
      case .GPS: 1
      case .GLONASS: 2
      case .galileo: 3
      case .beidou: 4
      case .QZSS: 5
      case .navIC: 6
      default: nil
    }
  }

  /**
   The ID number of a satellite in a GNSS constellation.

   GPS and Galileo satellites are identified by their pseudo-random number
   (PRN) ID, and GLONASS satellites are identified by their slot number. This
   is the ``PRN``.

   Because these IDs overlap, offsets are applied to the PRNs/slot numbers
   so that the IDs can share a number space. This is the SV ID.

   - SeeAlso: ``Message/Payload-swift.enum/GNSSFaultDetection(time:latitudeError:longitudeError:altitudeError:failedSatellite:missProbability:biasEstimate:biasEstimateStddev:)``
   - SeeAlso: ``Message/Payload-swift.enum/GNSSRangeResiduals(_:time:recomputed:)``
   - SeeAlso: ``Message/Payload-swift.enum/GNSS_DOP(PDOP:HDOP:VDOP:auto3D:solution:ids:)``
   */
  public enum SatelliteID: Sendable, Codable, Equatable, Hashable {

    /// Global Positioning System (US)
    case GPS(_ id: Int, signal: Signal.GPS?)

    /// GLONASS (ГЛОНАСС, Russia)
    case GLONASS(_ id: Int, signal: Signal.GLONASS?)

    /// Galileo positioning system
    case galileo(_ id: Int, signal: Signal.Galileo?)

    /// BeiDou Navigation Satellite System (北斗, China)
    case beidou(_ id: Int, signal: Signal.BDS?)

    /// Quasi-Zenith Satellite System (みちびき, Japan)
    case QZSS(_ id: Int, signal: Signal.QZSS?)

    /// NavIC / IRNSS (Indian Regional Navigation Satellite System)
    case navIC(_ id: Int, signal: Signal.NavIC?)

    /// The pseudo-random number ID for GPS and Galileo satellites, or the
    /// slot number for GLONASS satellites.
    public var PRN: Int? {
      switch self {
        case .GPS(let id, _):
          isAugmented ? id + 87 : id
        case .GLONASS(let id, _):
          id - 64
        case .galileo(let id, _):
          id
        case .beidou(let id, _), .QZSS(let id, _), .navIC(let id, _):
          id
      }
    }

    /// `true` if this satellite is part of a Space-Based Augmentation
    /// System (SBAS) or Wide-Area Augmentation System (WAAS) constellation.
    public var isAugmented: Bool {
      switch self {
        case .GPS(let id, _): (33...64).contains(id)
        case .GLONASS(let id, _): (33...64).contains(id)
        case .galileo(let id, _): (37...64).contains(id)
        case .beidou(let id, _): (65...85).contains(id)
        case .QZSS: false
        case .navIC(let id, _): (33...64).contains(id)
      }
    }

    init(systemID: Int, svID: Int, signalID: Int? = nil) throws {
      switch systemID {
        case 1:
          guard let signalID else {
            self = .GPS(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.GPS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .GPS(svID, signal: signal)
        case 2:
          guard let signalID else {
            self = .GLONASS(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.GLONASS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .GLONASS(svID, signal: signal)
        case 3:
          guard let signalID else {
            self = .galileo(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.Galileo(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .galileo(svID, signal: signal)
        case 4:
          guard let signalID else {
            self = .beidou(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.BDS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .beidou(svID, signal: signal)
        case 5:
          guard let signalID else {
            self = .QZSS(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.QZSS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .QZSS(svID, signal: signal)
        case 6:
          guard let signalID else {
            self = .navIC(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.NavIC(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .navIC(svID, signal: signal)
        default:
          throw Errors.badSystemID(systemID)
      }
    }

    init(svID: Int, signalID: Int? = nil) throws {
      switch svID {
        case 1...64:
          guard let signalID else {
            self = .GPS(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.GPS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .GPS(svID, signal: signal)
        case 65...99:
          guard let signalID else {
            self = .GLONASS(svID, signal: nil)
            return
          }
          guard let signal = GNSS.Signal.GLONASS(rawValue: signalID) else {
            throw Errors.badSignalID(signalID)
          }
          self = .GLONASS(svID, signal: signal)
        default:
          throw Errors.badSvID(svID)
      }
    }

    enum Errors: Swift.Error {
      case badSignalID(_ id: Int)
      case badSystemID(_ id: Int)
      case badSvID(_ id: Int)
    }
  }

  // swiftlint:disable:next missing_docs
  public struct Signal {
    private init() {}

    /// GPS signals/channels
    public enum GPS: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// L1 C/A
      case L1_CA = 1

      /// L1 P(Y)
      case L1_PY = 2

      /// L1 M
      case L1_M = 3

      /// L2 P(Y)
      case L2_PY = 4

      /// L2C-M
      case L2C_M = 5

      /// L2C-L
      case L2C_L = 6

      /// L5-I
      case L5_I = 7

      /// L5-Q
      case L5_Q = 8
    }

    /// GLONASS signals/channels
    public enum GLONASS: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// G1 C/A
      case G1_CA = 1

      /// G1 P
      case G1_P = 2

      /// G2 C/A
      case G2_CA = 3

      /// GLONASS (M) G2 P
      case G2_P = 4
    }

    /// Galileo signals/channels
    public enum Galileo: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// E5a
      case E5a = 1

      /// E5b
      case E5b = 2

      /// E5 a+b
      case E5ab = 3

      /// E6-A
      case E6_A = 4

      /// E6-BC
      case E6_BC = 5

      /// L1-A
      case L1_A = 6

      /// L1-BC
      case L1_BC = 7
    }

    /// BeiDou (BDS) signals/channels
    public enum BDS: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// B1I
      case B1I = 1

      /// B1Q
      case B1Q = 2

      /// B1C
      case B1C = 3

      /// B1A
      case B1A = 4

      /// B2a
      case B2a = 5

      /// B2b
      case B2b = 6

      /// B2 a+b
      case B2ab = 7

      /// B3I
      case B3I = 8

      /// B3Q
      case B3Q = 9

      /// B3A
      case B3A = 10

      /// B2I
      case B2I = 11

      /// B2Q
      case B2Q = 12
    }

    /// QZSS signals/channels
    public enum QZSS: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// L1 C/A
      case L1_CA = 1

      /// L1C (D)
      case L1C_D = 2

      /// L1C (P)
      case L1C_P = 3

      /// L1S
      case L1S = 4

      /// L2C-M
      case L2C_M = 5

      /// L2C-L
      case L2C_L = 6

      /// L5-I
      case L5_I = 7

      /// L5-Q
      case L5_Q = 8

      /// L6D
      case L6D = 9

      /// L6E
      case L6E = 10
    }

    /// NavIC (IRNSS) signals/channels
    public enum NavIC: Int, Sendable, Codable, Equatable {

      /// All signals
      case all = 0

      /// L5-SPS
      case L5_SPS = 1

      /// S-SPS
      case S_SPS = 2

      /// L5-RS
      case L5_RS = 3

      /// S-RS
      case S_RS = 4

      /// L1-SPS
      case L1_SPS = 5
    }
  }

  /**
   Possible sources of integrity data.

   - SeeAlso: ``IntegrityStatus``
   - SeeAlso: ``Message/Payload-swift.enum/GNSSAccuracyIntegrity(time:HPL:VPL:semimajorStddev:semiminorStddev:semimajorErrorOrientation:altitudeStddev:selectedAccuracy:integrity:)``
   */
  public enum IntegritySource: Sendable, Codable, Equatable {

    /// Receiver Autonomous Integrity Monitoring (GPS)
    case RAIM

    /// Satellite-Based Augmentation System (WAAS)
    case SBAS

    /// Galileo Integrity
    case GIC
  }

  /**
   The integrity status of an ``IntegritySource``.

   - SeeAlso: ``Message/Payload-swift.enum/GNSSAccuracyIntegrity(time:HPL:VPL:semimajorStddev:semiminorStddev:semimajorErrorOrientation:altitudeStddev:selectedAccuracy:integrity:)``
   - SeeAlso: ``Message/Payload-swift.enum/GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
   */
  public enum IntegrityStatus: Character, Sendable, Codable, Equatable {

    ///  Navigational status not valid, equipment is not providing
    /// navigational status indication.
    case notInUse = "V"

    /**
     Safe (when integrity is available and HPL<HAL)

     When the estimated positioning accuracy (95 % confidence) is within the
     selected accuracy level corresponding to the actual navigation mode,
     and integrity is available and within the requirements for the actual
     navigation mode, and a new valid position has been calculated within
     1 s for a conventional craft and 0,5 s for a high speed craft.
     */
    case safe = "S"

    /// Caution (when integrity is not available)
    case caution = "C"

    /**
     Unsafe (when integrity is available and HPL>HAL)

     When the estimated positioning accuracy (95 % confidence) is less than
     the selected accuracy level corresponding to the actual navigation
     mode, and/or integrity is available but exceeds the requirements for
     the actual navigation mode, and/or a new valid position has not been
     calculated within 1 s for a conventional craft and 0,5 s for a high
     speed craft.
     */
    case unsafe = "U"
  }

  /**
   GPS quality indicator. All quality indicators except ``invalid`` are
   considered valid.

   - SeeAlso: ``Message/Payload-swift.enum/GPSFix(_:time:quality:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:)``
   */
  public enum GPSQuality: Int, Sendable, Codable, Equatable {

    /// Fix not available or invalid
    case invalid = 0

    /// GPS Standard Positioning Service (SPS) mode
    case SPS = 1

    /// differential GPS, SPS mode (WAAS)
    case differentialSPS = 2

    /// GPS Precise Positioning Service (PPS) mode
    case PPS = 3

    /// Real Time Kinematic. Satellite system used in RTK mode with fixed integers
    case RTK = 4

    /// Float RTK. Satellite system used in RTK mode with floating solution
    case floatRTK = 5

    /// Estimated (dead reckoning) mode
    case estimated = 6

    /// Manual input mode
    case manual = 7

    /// Simulator mode
    case simulator = 8
  }

  /**
   GNSS systems and constellations.

   - SeeAlso: ``Message/Payload-swift.enum/GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
   */
  public enum System: Sendable, Codable, Equatable {

    /// Global Positioning System (US)
    case GPS

    /// GLONASS (ГЛОНАСС, Russia)
    case GLONASS

    /// Galileo positioning system
    case galileo

    /// BeiDou Navigation Satellite System (北斗, China)
    case beidou

    /// Quasi-Zenith Satellite System (みちびき, Japan)
    case QZSS

    /// NavIC / IRNSS (Indian Regional Navigation Satellite System)
    case navIC
  }

  /**
   Types of GPS solutions based on the number of satellites in use.

   - SeeAlso: ``Message/Payload-swift.enum/GNSS_DOP(PDOP:HDOP:VDOP:auto3D:solution:ids:)``
   */
  public enum SolutionType: Int, Sendable, Codable, Equatable {

    /// Fix not available
    case none = 1

    /// 2D fix
    case fix2D = 2

    /// 3D fix
    case fix3D = 3
  }

  /// A position on the celestial sphere relative to earth's horizon.
  public struct CelestialPosition: Sendable, Codable, Equatable {

    /// The elevation in degrees above the horizon.
    public let elevation: Measurement<UnitAngle>

    /// The azimuth in degrees relative to true north.
    public let azimuth: Bearing
  }

  /**
   Information about a satellite in view.

   - SeeAlso: ``Message/Payload-swift.enum/GNSSSatellitesInView(_:total:)``
   */
  public struct SatelliteInView: Sendable, Codable, Equatable {

    /// The satellite ID
    public let id: SatelliteID

    /// The celestial position of the satellite
    public let position: CelestialPosition

    /// SNR (C/N₀) [carrier-to-noise density ratio], 00-99 dB-Hz.
    /// `nil` when not tracking.
    public let SNR: Int?
  }
}
