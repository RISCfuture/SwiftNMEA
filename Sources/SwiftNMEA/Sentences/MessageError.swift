/// When a ``ParametricSentence`` can't be parsed into a ``Message``, a
/// `MessageError` is created instead and added to the stream from
/// ``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)``. The `MessageError`
/// object allows you get more information about the parsing error.
public struct MessageError: Element, Sendable, Codable, Equatable {
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

  init(from error: NMEAError) {
    self.type = error.type
    self.line = error.line
    self.fieldNumber = error.fieldNumber
    self.value = error.value
  }
}

/// Possible NMEA parsing errors.
public enum ErrorType: Sendable, Codable, Equatable {

  /// A numeric value was expected.
  case badNumericValue

  /// A measurement unit (e.g., meters) was expected.
  case badUnitValue

  /// A latitude or longitude was expected.
  case badLatLon

  /// A date (year-month-day) was invalid.
  case badDate

  /// A time (hours-minutes-seconds) was expected.
  case badTime

  /// A value was in an unexpected format.
  case badValue

  /// A message line was not in ASCII format.
  case badEncoding

  /// A six-bit-encoded value was bad.
  case badSixBitEncoding

  /// Checksum did not match sentence payload.
  case wrongChecksum

  /// Sentence type did not have an associated MessageFormat subclass.
  case unknownSentenceType

  /// Expected a single character.
  case badCharacterValue

  /// Unknown enumeration value.
  case unknownValue

  /// Sentence number for a multi-part message exceeded total sentence count.
  case wrongSentenceNumber

  /// A required value is missing.
  case missingRequiredValue

  /// Approved talker ID was unknown.
  case unknownTalker

  /// Format ID was unknown.
  case unknownFormat

  /// Format ID was not expected (for multi-sentence formats).
  case unexpectedFormat

  /// Expected a sentence of a certain format but didn't receive it.
  case missingFormat
}
