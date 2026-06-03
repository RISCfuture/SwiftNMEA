import Foundation

/// Types related to radar equipment.
public struct Radar {
  private init() {}

  /**
   System target status.

   - SeeAlso: ``Message/Payload-swift.enum/targetPosition(number:position:name:time:status:isReference:)``
   - SeeAlso: ``Message/Payload-swift.enum/trackedTarget(number:distance:bearing:speed:course:CPADistance:CPATime:name:status:isReference:time:acquisition:)``
   */
  public enum TargetStatus: Character, Sendable, Codable, Equatable {

    /// Lost, tracked target has been lost
    case lost = "L"

    /// Query, target in the process of acquisition
    case query = "Q"

    /// Tracking
    case tracking = "T"
  }

  /**
   Tracked target acquisition types.

   - SeeAlso: ``Message/Payload-swift.enum/trackedTarget(number:distance:bearing:speed:course:CPADistance:CPATime:name:status:isReference:time:acquisition:)``
   */
  public enum AcquisitionType: Character, Sendable, Codable, Equatable {
    case automatic = "A"
    case manual = "M"
    case reported = "R"
  }

  public struct TrackedTarget: Sendable, Codable, Equatable {

    /// Protocol version
    public let protocolVersion: UInt8

    /// The target number associated with the label with corresponding
    /// number. `nil` for no tracking target.
    public let number: UInt?

    /// True bearing. `nil` = Invalid or N/A data
    public let bearing: Bearing?

    /**
     Speed. `nil` = Invalid or N/A data

     - SeeAlso: ``speedCourseRelative``
     - SeeAlso: ``waterStabilized``
     */
    public let speed: Measurement<UnitSpeed>?

    /**
     Course. `nil` = Invalid or N/A data

     - SeeAlso: ``speedCourseRelative``
     - SeeAlso: ``waterStabilized``
     */
    public let course: Measurement<UnitAngle>?

    /**
     Reported heading from AIS, north-up coordinate system. `nil` = Invalid
     or N/A data, or radar target.

     - SeeAlso: ``isRadarTarget``
     */
    public let heading: Measurement<UnitAngle>?

    /// `true`: Relative speed and course; `false`: True speed and course
    public let speedCourseRelative: Bool

    /// Stabilisation mode. `true`: Through the water; `false`: Over the ground
    public let waterStabilized: Bool

    /// `true` = radar target; `false` = AIS target
    public let isRadarTarget: Bool

    /// Tracked / AIS target status
    public let status: Status?

    /// `true`: Test target; `false`: Autonomous (normal)
    public let isTestTarget: Bool

    /// Distance to target. `nil` = invalid or N/A data
    public let distance: Measurement<UnitLength>?

    /// Correlation / Association number. Correlated / associated targets
    /// are assigned a common number. `nil` is reserved for no
    /// correlation / association.
    public let correlationNumber: UInt8?

    /// Distance of closest point of approach. Only present for protocol
    /// version one structures. `nil` = invalid or N/A data.
    public let CPADistance: Measurement<UnitLength>?

    /// Time to closest point of approach. Only present for protocol version
    /// one structures. "-" = increasing. `nil` = invalid or N/A data.
    public let CPATime: Measurement<UnitDuration>?

    init(reader: inout BitReader) throws {
      let version: UInt8 = reader.peek(bits: 2)
      switch version {
        case 0: try self.init(protocolZeroReader: &reader)
        case 1: try self.init(protocolOneReader: &reader)
        default: throw DecodingError.unknownProtocolVersion
      }
    }

    private init(protocolZeroReader reader: inout BitReader) throws {
      guard reader.remainingBits >= 90 else { throw DecodingError.truncated }

      protocolVersion = reader.read(bits: 2)
      let trackNum: UInt = reader.read(bits: 10)
      number = trackNum == 0 ? nil : trackNum
      let beraringValue: UInt16 = reader.read(bits: 12)
      let bearingMeasurement = Self.decodeDecimal(
        beraringValue,
        unit: UnitAngle.degrees,
        nilSentinel: 4095
      )
      let speedValue: UInt16 = reader.read(bits: 12)
      let courseValue: UInt16 = reader.read(bits: 12)
      let headingValue: UInt16 = reader.read(bits: 12)
      bearing = bearingMeasurement.map { .init(angle: $0, reference: .true) }
      speed = Self.decodeDecimal(speedValue, unit: UnitSpeed.knots, nilSentinel: 4095)
      course = Self.decodeDecimal(courseValue, unit: UnitAngle.degrees, nilSentinel: 4095)
      heading = Self.decodeDecimal(headingValue, unit: UnitAngle.degrees, nilSentinel: 4094, 4095)
      isRadarTarget = headingValue == 4095
      status = .init(rawValue: reader.read(bits: 3))
      isTestTarget = reader.readFlag()
      let distanceValue: UInt16 = reader.read(bits: 14)
      distance = Self.decodeDecimal(
        distanceValue,
        unit: UnitLength.nauticalMiles,
        step: 0.01,
        nilSentinel: 16383
      )
      speedCourseRelative = reader.readFlag()
      waterStabilized = reader.readFlag()
      let _: UInt8 = reader.read(bits: 2)
      let corr: UInt8 = reader.read(bits: 8)
      correlationNumber = corr == 0 ? nil : corr
      CPADistance = nil
      CPATime = nil
    }

    private init(protocolOneReader reader: inout BitReader) throws {
      guard reader.remainingBits >= 42 else { throw DecodingError.truncated }

      protocolVersion = reader.read(bits: 2)
      let trackNum: UInt = reader.read(bits: 10)
      number = trackNum == 0 ? nil : trackNum
      let CPAValue: UInt16 = reader.read(bits: 14)
      CPADistance = Self.decodeDecimal(
        CPAValue,
        unit: UnitLength.nauticalMiles,
        step: 0.01,
        nilSentinel: 16383
      )
      // TCPA is encoded as a 14-bit two's-complement value; -8192 (-81,92 min)
      // is the invalid / not-available sentinel.
      let TCPAValue: Int16 = reader.read(bits: 14)
      CPATime =
        TCPAValue == -8192
        ? nil : Measurement(value: Double(TCPAValue) * 0.01, unit: .minutes)
      let _: UInt8 = reader.read(bits: 2)

      // Fields that only exist in protocol version zero structures.
      bearing = nil
      speed = nil
      course = nil
      heading = nil
      isRadarTarget = false
      status = nil
      isTestTarget = false
      distance = nil
      speedCourseRelative = false
      waterStabilized = false
      correlationNumber = nil
    }

    private static func decodeDecimal<Unit: Dimension>(
      _ rawValue: UInt16,
      unit: Unit,
      step: Double = 0.1,
      nilSentinel: UInt16...
    ) -> Measurement<Unit>? {
      if nilSentinel.contains(rawValue) { return nil }

      let value = Double(rawValue) * step
      return Measurement(value: value, unit: unit)
    }

    /// An error decoding a tracked target bit structure.
    enum DecodingError: Error {

      /// The protocol version is neither zero nor one.
      case unknownProtocolVersion

      /// The bitstream ended before a complete target structure could be read.
      case truncated
    }

    /// Tracked / AIS target status
    public enum Status: UInt8, Sendable, Codable, Equatable {

      /// Radar: Non-tracking; AIS: No target to report
      case none = 0b000

      /// Radar: Acquiring target (not established); AIS: Sleeping target
      case acquiringSleeping = 0b001

      /// Lost target
      case lost = 0b010

      /// Radar: Established tracking, no alarm;
      /// AIS: Activated target, no alarm
      case activatedNoAlarm = 0b100

      /// Radar: Established tracking, CPA/TCPA alarm;
      /// AIS: Activated target, CPA/TCPA alarm
      case activatedAlarm = 0b110

      /// Radar: Established tracking, acknowledged CPA/TCPA alarm;
      /// AIS: Activated target, acknowledged CPA/TCPA alarm
      case activatedAlarmAcknowledged = 0b111
    }
  }
}
