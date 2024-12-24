import Foundation

protocol MeasurementValue: Sendable, Codable, Equatable, RawRepresentable where RawValue == String {
    associatedtype Unit: Dimension

    static var unit: Unit { get }
    var measurement: Measurement<Unit> { get}

    init(measurement: Measurement<Unit>)
}

// swiftlint:disable extension_access_modifier missing_docs
extension MeasurementValue {
    public var rawValue: String {
        String(format: "%04.0f", measurement.value * 10)
    }

    public init?(rawValue: String) {
        guard let tens = Int(rawValue) else { return nil }
        let value = Double(tens) / 10
        self.init(measurement: .init(value: value, unit: Self.unit))
    }
}
// swiftlint:enable extension_access_modifier missing_docs

/// A speed, in knots.
public struct Speed: MeasurementValue {
    typealias Unit = UnitSpeed

    static let unit = UnitSpeed.knots

    /// The speed value.
    public let measurement: Measurement<UnitSpeed>
}

/// A true or magnetic course, in degrees.
public struct Course: MeasurementValue {
    typealias Unit = UnitAngle

    static let unit = UnitAngle.degrees

    /// The course value.
    public let measurement: Measurement<UnitAngle>
}

/// A plaintext value. Commas (0x2C) are substituted with apostrophes (0x27)
/// in the encoded ``rawValue``, as commas are reserved in NMEA sentences.
public struct Text: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /// The plaintext.
    public let value: String

    public var rawValue: String { value.replacingOccurrences(of: ",", with: "'") }

    public init?(rawValue: String) {
        value = rawValue.replacingOccurrences(of: "'", with: ",")
    }
}

/// A numeric integer value.
public struct Number: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /// The number.
    public let value: Int

    public var rawValue: String { String(format: "%04d", value) }

    public init?(rawValue: String) {
        guard let value = Int(rawValue) else { return nil }
        self.value = value
    }
}
