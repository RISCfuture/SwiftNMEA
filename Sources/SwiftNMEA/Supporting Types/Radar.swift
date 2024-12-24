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

        var data: Data {
            var writer = BitWriter(size: 90)
            writer.write(protocolVersion, bits: 2)
            writer.write(number ?? 0, bits: 10)
            writer.write(Self.encodeDecimal(bearing?.angle, unit: .degrees, nilSentinal: 4095), bits: 12)
            writer.write(Self.encodeDecimal(speed, unit: .knots, nilSentinal: 4095), bits: 12)
            writer.write(Self.encodeDecimal(course, unit: .degrees, nilSentinal: 4095), bits: 12)
            if isRadarTarget {
                writer.write(4095, bits: 12)
            } else {
                writer.write(Self.encodeDecimal(heading, unit: .degrees, nilSentinal: 4094), bits: 12)
            }
            writer.write(status?.rawValue ?? 0, bits: 3)
            writer.write(isTestTarget ? 1 : 0, bits: 1)
            writer.write(Self.encodeDecimal(distance, unit: .nauticalMiles, step: 0.01, nilSentinal: 16384), bits: 14)
            writer.write(speedCourseRelative ? 1 : 0, bits: 1)
            writer.write(waterStabilized ? 1 : 0, bits: 1)
            writer.write(0, bits: 2)
            writer.write(correlationNumber ?? 0, bits: 8)

            return writer.data
        }

        init?(data: Data) {
            var reader = BitReader(data: data)
            self.init(reader: &reader)
        }

        init(reader: inout BitReader) {
            protocolVersion = reader.read(bits: 2)
            let trackNum: UInt = reader.read(bits: 10)
            number = trackNum == 0 ? nil : trackNum
            let beraringValue: UInt16 = reader.read(bits: 12),
                bearingMeasurement = Self.decodeDecimal(beraringValue, unit: UnitAngle.degrees, nilSentinel: 4095),
                speedValue: UInt16 = reader.read(bits: 12),
                courseValue: UInt16 = reader.read(bits: 12),
                headingValue: UInt16 = reader.read(bits: 12)
            bearing = bearingMeasurement.map { .init(angle: $0, reference: .true) }
            speed = Self.decodeDecimal(speedValue, unit: UnitSpeed.knots, nilSentinel: 4095)
            course = Self.decodeDecimal(courseValue, unit: UnitAngle.degrees, nilSentinel: 4095)
            heading = Self.decodeDecimal(headingValue, unit: UnitAngle.degrees, nilSentinel: 4094, 4095)
            isRadarTarget = headingValue == 4095
            status = .init(rawValue: reader.read(bits: 3))
            isTestTarget = reader.read(bits: 1) == 1
            let distanceValue: UInt16 = reader.read(bits: 14)
            distance = Self.decodeDecimal(distanceValue, unit: UnitLength.nauticalMiles, step: 0.01, nilSentinel: 16384)
            speedCourseRelative = reader.read(bits: 1) == 1
            waterStabilized = reader.read(bits: 1) == 1
            let _: UInt8 = reader.read(bits: 2),
                corr: UInt8 = reader.read(bits: 8)
            correlationNumber = corr == 0 ? nil : corr
        }

        private static func decodeDecimal<Unit: Dimension>(_ rawValue: UInt16, unit: Unit, step: Double = 0.1, nilSentinel: UInt16...) -> Measurement<Unit>? {
            if nilSentinel.contains(rawValue) { return nil }

            let value = Double(rawValue) * step
            return Measurement(value: value, unit: unit)
        }

        private static func encodeDecimal<Unit: Dimension>(_ measurement: Measurement<Unit>?, unit: Unit, step: Double = 0.1, nilSentinal: UInt16) -> UInt16 {
            guard let measurement else { return nilSentinal }
            let value = measurement.converted(to: unit).value
            return UInt16((value / step).rounded())
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
