import Foundation
import NMEACommon

/**
 This class stores comma-delimited data found in a sentence. The format of a
 sentence is something akin to: `"$ABC,DEF,GH*12*"` where `$` is the delimiter,
 `ABC,DEF,GH` are the fields, and `12` is the checksum (calculated from the
 fields but not the delimiter.

 The first field is typically the address, and is handled specially as such.
 The first field (#0) is only accessible through ``address``; calling any of the
 subscript operators uses a subset of the fields _not_ including the address.
 */
public struct Fields: Sendable, Codable, Equatable {
    private static var latitudeParser: LatitudeParser { .init() }
    private static var longitudeParser: LongitudeParser { .init() }
    private static var timeParser: TimeParser { .init() }
    private static var sixBitParser: SixBitCoder { .init() }

    private var fields: [String?]

    /// The value of the 0th field, typically the address. This field is not
    /// included in the subscript operator.
    public var address: String { fields[0]! }

    /// The last index of the fields array.
    public var endIndex: Int { fields.endIndex - 1 }

    /// The number of fields, not including the ``address``.
    public var count: Int { fields.count - 1 }

    var rawFields: [String] { fields.map { $0 ?? "" } }
    var rawValue: String { rawFields.joined(separator: ",") }

    var checksum: UInt8 { calculateChecksum(for: rawValue) }

    init(fields: [String?]) {
        precondition(fields.count >= 1 && fields[0] != nil,
                     "Fields must include an address")
        self.fields = fields
    }

    init(data: any StringProtocol) {
        fields = data.components(separatedBy: ",").map { $0.isEmpty ? nil : $0 }
        precondition(fields.count >= 1 && fields[0] != nil,
                     "Fields must include an address")
    }

    func lineError(type: ErrorType) -> NMEAError {
        return .init(type: type, line: rawValue)
    }

    func fieldError(type: ErrorType, index: Int) -> NMEAError {
        return .init(type: type, line: rawValue, fieldNumber: index, value: self[index])
    }

    func character(at valueIndex: Int, optional: Bool = false) throws -> Character? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard value.count == 1 else {
            throw fieldError(type: .badCharacterValue, index: valueIndex)
        }
        return value.first!
    }

    func string(at valueIndex: Int, optional: Bool = false) throws -> String? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        return value
    }

    func int(at valueIndex: Int, optional: Bool = false) throws -> Int? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard let intValue = Int(value) else {
            throw fieldError(type: .badNumericValue, index: valueIndex)
        }
        return intValue
    }

    func float(at valueIndex: Int, optional: Bool = false) throws -> Double? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard let doubleValue = Double(value) else {
            throw fieldError(type: .badNumericValue, index: valueIndex)
        }
        return doubleValue
    }

    func bool(at valueIndex: Int, trueValue: String = "A", falseValue: String = "V", optional: Bool = false) throws -> Bool? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        if value == trueValue { return true }
        if value == falseValue { return false }
        throw fieldError(type: .badValue, index: valueIndex)
    }

    func hex(at valueIndex: Int, width: Int?, optional: Bool = false) throws -> UInt? {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        if let width, value.count != width {
            throw fieldError(type: .badNumericValue, index: valueIndex)
        }
        guard let parsedValue = UInt(value, radix: 16) else {
            throw fieldError(type: .badNumericValue, index: valueIndex)
        }
        return parsedValue
    }

    func enumeration<T: RawRepresentable>(at valueIndex: Int, ofType _: T.Type, optional: Bool = false) throws -> T? where T.RawValue == String {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard let enumValue = T(rawValue: value) else {
            throw fieldError(type: .unknownValue, index: valueIndex)
        }
        return enumValue
    }

    func enumeration<T: RawRepresentable>(at valueIndex: Int, ofType _: T.Type, optional: Bool = false) throws -> T? where T.RawValue == Character {
        guard let value = self[valueIndex] else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard let char = value.first,
              let enumValue = T(rawValue: char) else {
            throw fieldError(type: .unknownValue, index: valueIndex)
        }
        return enumValue
    }

    func enumeration<T: RawRepresentable>(at valueIndex: Int, ofType _: T.Type, optional: Bool = false) throws -> T? where T.RawValue == Int {
        guard let value = try int(at: valueIndex, optional: optional) else {
            if optional { return nil }
            throw lineError(type: .missingRequiredValue)
        }
        guard let enumValue = T(rawValue: value) else {
            throw fieldError(type: .unknownValue, index: valueIndex)
        }
        return enumValue
    }

    func measurement<U>(at valueIndex: Int, valueType: ValueType, unitAt unitIndex: Int, units: [String: U], optional: Bool = false) throws -> Measurement<U>? {
        guard let value = switch valueType {
        case .integer: try toFloat(int(at: valueIndex, optional: optional))
        case .float: try float(at: valueIndex, optional: optional)
        } else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: valueIndex)
        }

        guard let unitStr = self[unitIndex] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: unitIndex)
        }
        guard let unit = units[unitStr] else {
            throw fieldError(type: .badUnitValue, index: unitIndex)
        }

        return .init(value: value, unit: unit)
    }

    func measurement<U: Dimension>(at valueIndex: Int, valueType: ValueType, units: U, optional: Bool = false) throws -> Measurement<U>? {
        guard let value = switch valueType {
        case .integer: try toFloat(int(at: valueIndex, optional: optional))
        case .float: try float(at: valueIndex, optional: optional)
        } else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: valueIndex)
        }

        return .init(value: value, unit: units)
    }

    func bearing(at valueIndex: Int, valueType: ValueType, referenceIndex: Int, optional: Bool = false) throws -> Bearing? {
        guard let reference = try enumeration(at: referenceIndex, ofType: Bearing.Reference.self, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: referenceIndex)
        }
        return try bearing(at: valueIndex, valueType: valueType, reference: reference, optional: optional)
    }

    func bearing(at valueIndex: Int, valueType: ValueType, reference: Bearing.Reference, optional: Bool = false) throws -> Bearing? {
        guard let value = switch valueType {
        case .integer: try toFloat(int(at: valueIndex, optional: optional))
        case .float: try float(at: valueIndex, optional: optional)
        } else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: valueIndex)
        }
        return .init(degrees: value, reference: reference)
    }

    func deviation(at valueIndex: (Int, Int), valueType: ValueType, optional: Bool = false) throws -> Measurement<UnitAngle>? {
        guard var value = switch valueType {
        case .integer: try toFloat(int(at: valueIndex.0, optional: optional))
        case .float: try float(at: valueIndex.0, optional: optional)
        } else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: valueIndex.0)
        }
        switch self[valueIndex.1] {
            case "E": break
            case "W": value *= -1
            case nil: throw fieldError(type: .missingRequiredValue, index: valueIndex.1)
            default: throw fieldError(type: .badValue, index: valueIndex.1)
        }
        return .init(value: value, unit: .degrees)
    }

    func position(latitudeIndex: (Int, Int),
                  longitudeIndex: (Int, Int),
                  altitudeIndex: (Int, Int?)? = nil,
                  optional: Bool = false,
                  altitudeOptional: Bool = true,
                  altitudeType: ValueType = .integer) throws -> Position? {
        guard let latitudeHemisphere = try enumeration(at: latitudeIndex.1, ofType: LatitudeHemisphere.self, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: latitudeIndex.1)
        }
        guard let latitudeStr = try string(at: latitudeIndex.0, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: latitudeIndex.0)
        }
        guard let longitudeHemisphere = try enumeration(at: longitudeIndex.1, ofType: LongitudeHemisphere.self, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: longitudeIndex.1)
        }
        guard let longitudeStr = try string(at: longitudeIndex.0, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: longitudeIndex.0)
        }
        guard let latitude = try Self.latitudeParser.parse(latitudeStr, hemisphere: latitudeHemisphere) else {
            throw fieldError(type: .badLatLon, index: latitudeIndex.0)
        }
        guard let longitude = try Self.longitudeParser.parse(longitudeStr, hemisphere: longitudeHemisphere) else {
            throw fieldError(type: .badLatLon, index: longitudeIndex.0)
        }

        let altitude = try altitudeIndex.flatMap { altitudeIndex in
            if let unitAt = altitudeIndex.1 {
                return try measurement(at: altitudeIndex.0, valueType: altitudeType, unitAt: unitAt, units: lengthUnits, optional: altitudeOptional)
            }
            return try measurement(at: altitudeIndex.0, valueType: altitudeType, units: UnitLength.meters, optional: altitudeOptional)
        }

        return .init(latitude: latitude, longitude: longitude, altitude: altitude)
    }

    func ymd(at index: Int, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let dateStr = try string(at: index, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: index)
        }
        guard dateStr.count == 8,
              let day = Int(dateStr.slice(from: 0, to: 1)),
              let month = Int(dateStr.slice(from: 2, to: 3)),
              let year = Int(dateStr.slice(from: 4, to: 7)) else {
            throw fieldError(type: .badDate, index: index)
        }
        guard let date = Self.timeParser.calendar.date(from: .init(timeZone: timeZone, year: year, month: month, day: day)) else {
            throw lineError(type: .badDate)
        }
        return date
    }

    func ymd(yearIndex: Int, monthIndex: Int, dayIndex: Int, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let year = try int(at: yearIndex, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: yearIndex)
        }
        guard let month = try int(at: monthIndex, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: monthIndex)
        }
        guard let day = try int(at: dayIndex, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: dayIndex)
        }

        guard let date = Self.timeParser.calendar.date(from: .init(timeZone: timeZone, year: year, month: month, day: day)) else {
            throw lineError(type: .badDate)
        }
        return date
    }

    func hmsDecimal(at index: Int, searchDirection: Calendar.SearchDirection, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let valueStr = self[index] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: index)
        }
        if valueStr.contains(".") {
            guard let time = try Self.timeParser.parseHmsDecimal(valueStr, searchDirection: searchDirection, timeZone: timeZone) else {
                throw fieldError(type: .badTime, index: index)
            }
            return time
        }
        guard let time = try Self.timeParser.parseHms(valueStr, searchDirection: searchDirection, timeZone: timeZone) else {
            throw fieldError(type: .badTime, index: index)
        }
        return time
    }

    func hmsDecimalDuration(at index: Int, optional: Bool = false) throws -> Duration? {
        guard let valueStr = self[index] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: index)
        }
        guard let time = try Self.timeParser.parseHmsDecimalDuration(valueStr) else {
            throw fieldError(type: .badTime, index: index)
        }
        return time
    }

    func datetime(ymdIndex: (Int, Int, Int), hmsDecimalIndex: Int, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let year = try int(at: ymdIndex.0, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.0)
        }
        guard let month = try int(at: ymdIndex.1, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.1)
        }
        guard let day = try int(at: ymdIndex.2, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.2)
        }
        guard let timeStr = self[hmsDecimalIndex] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: hmsDecimalIndex)
        }
        guard let dayPortion = Self.timeParser.calendar.date(from: .init(timeZone: timeZone, year: year, month: month, day: day)) else {
            throw lineError(type: .badDate)
        }
        guard let date = try Self.timeParser.parseHmsDecimal(timeStr, searchDirection: .forward, referenceDate: dayPortion, timeZone: timeZone) else {
            throw fieldError(type: .badTime, index: hmsDecimalIndex)
        }
        return date
    }

    func datetime(ymdIndex: (Int, Int, Int), hmsIndex: Int, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let year = try int(at: ymdIndex.0, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.0)
        }
        guard let month = try int(at: ymdIndex.1, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.1)
        }
        guard let day = try int(at: ymdIndex.2, optional: optional) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex.2)
        }
        guard let timeStr = self[hmsIndex] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: hmsIndex)
        }
        guard let dayPortion = Self.timeParser.calendar.date(from: .init(timeZone: timeZone, year: year, month: month, day: day)) else {
            throw lineError(type: .badDate)
        }
        guard let date = try Self.timeParser.parseHms(timeStr, searchDirection: .forward, referenceDate: dayPortion, timeZone: timeZone) else {
            throw fieldError(type: .badTime, index: hmsIndex)
        }
        return date
    }

    func datetime(ymdIndex: Int, hmsDecimalIndex: Int, optional: Bool = false, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let dayPortion = try ymd(at: ymdIndex, optional: optional, timeZone: timeZone) else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: ymdIndex)
        }
        guard let timeStr = self[hmsDecimalIndex] else {
            if optional { return nil }
            throw fieldError(type: .missingRequiredValue, index: hmsDecimalIndex)
        }
        guard let date = try Self.timeParser.parseHmsDecimal(timeStr, searchDirection: .forward, referenceDate: dayPortion, timeZone: timeZone) else {
            throw fieldError(type: .badTime, index: hmsDecimalIndex)
        }
        return date
    }

    private func toFloat(_ int: Int?) -> Double? {
        int.map { Double($0) }
    }

    /**
     Returns the value for a field. Index #0 is the first field _after_ the
     ``address``.

     - Parameter index: The field index.
     - Returns: The value at that index.
     */
    public subscript(index: Array.Index) -> String? { fields[safe: index + 1]?.flatMap(\.self) }

    public subscript(bounds: Range<Array.Index>) -> ArraySlice<String?> { fields[bounds.succ] }
    public subscript(bounds: ClosedRange<Array.Index>) -> ArraySlice<String?> { fields[bounds.succ] }
    public subscript(bounds: PartialRangeFrom<Array.Index>) -> ArraySlice<String?> { fields[bounds.succ] }
    public subscript(bounds: PartialRangeUpTo<Array.Index>) -> ArraySlice<String?> { fields[bounds.succ] }
    public subscript(bounds: PartialRangeThrough<Array.Index>) -> ArraySlice<String?> { fields[bounds.succ] }

    enum ValueType { case integer, float }
}
