/// Empty protocol that encompasses all parsed output types (``Sentence``s and
///  ``Message``s).
public protocol Element: Sendable, Codable, Equatable {}

/// Protocol that encompasses all sentence types (query, parametric,
/// encapsulated, proprietary).
public protocol Sentence: Sendable, Codable, Equatable {

  /// The delimiter indicating sentence structure.
  var delimiter: Delimiter { get }

  /// The message fields.
  var fields: Fields { get }

  /// The message checksum.
  var checksum: UInt8 { get }

  /// `true` if the checksum is valid.
  var checksumIsValid: Bool { get }

  /**
   Creates a new record from a given sentence. Returns `nil` if the sentence
   structure does not match the message format.
  
   - Parameter sentence: The sentence string, not including CRLF.
   - Parameter ignoreChecksum: If `true`, does not validate the checksum.
   - Throws: If the checksum was incorrect.
   */
  init?(sentence: String, ignoreChecksum: Bool) async throws
}

extension Sentence {
  internal var checksumString: String { .init(format: "%02X", checksum) }

  /// The sentence, encoded for transmission, including newlines.
  public var rawValue: String { "\(delimiter.rawValue)\(fields.rawValue)*\(checksumString)\r\n" }

  /// `true` if the given ``checksum`` checksum matches the calculated value.
  public var checksumIsValid: Bool { fields.checksum == checksum }
}
