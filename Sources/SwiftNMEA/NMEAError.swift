import Foundation

/// An error that occurred when parsing an NMEA sentence.
public struct NMEAError: Error {

    /// The type of parsing error.
    public let type: ErrorType

    /// The contents of the line with the error.
    public let line: String?

    /// The field number (0-indexed) that could not be parsed (if applicable).
    public let fieldNumber: Int?

    /// The value of the field (if applicable).
    public let value: String?

    init(type: ErrorType, line: String? = nil, fieldNumber: Int? = nil, value: String? = nil) {
        self.type = type
        self.line = line
        self.fieldNumber = fieldNumber
        self.value = value
    }
}

extension NMEAError: LocalizedError {
    public var errorDescription: String? {
        if let fieldNumber {
            return String(localized: "Couldn’t parse NMEA data: \(localizedType). (field #\(fieldNumber))")
        }
        return String(localized: "Couldn’t parse NMEA data: \(localizedType).")
    }

    public var failureReason: String? {
        if let line {
            String(localized: "NMEA sentence was invalid: \(line)")
        } else {
            String(localized: "NMEA sentence was invalid.")
        }
    }

    private var localizedType: String {
        switch type {
            case .badNumericValue: return String(localized: "Bad numeric value.")
            case .badUnitValue: return String(localized: "Bad numeric unit value.")
            case .badValue: return String(localized: "Bad value.")
            case .badLatLon: return String(localized: "Bad latitude or longitude.")
            case .badDate: return String(localized: "Bad year/month/day.")
            case .badTime: return String(localized: "Bad hours/minutes/seconds time.")
            case .badEncoding: return String(localized: "Sentence was not ASCII-encoded.")
            case .badSixBitEncoding: return String(localized: "Field was not properly six-bit coded.")
            case .wrongChecksum: return String(localized: "Checksum did not match sentence payload.")
            case .unknownSentenceType: return String(localized: "Sentence type was not recognized.")
            case .badCharacterValue: return String(localized: "Field must be a single character.")
            case .unknownValue: return String(localized: "Field has an unknown value.")
            case .wrongSentenceNumber: return String(localized: "Sentence number exceeded total sentence count.")
            case .missingRequiredValue: return String(localized: "Sentence was missing a required field.")
            case .unknownTalker:
                if let value {
                    return String(localized: "Unknown talker ID “\(value)”.")
                }
                return String(localized: "Unknown talker ID.")
            case .unknownFormat:
                if let value {
                    return String(localized: "Unknown format ID “\(value)”.")
                }
                return String(localized: "Unknown format ID.")
            case .unexpectedFormat: return String(localized: "Unexpected format ID.")
            case .missingFormat: return String(localized: "Expected a sentence format that wasn’t received.")
        }
    }
}
