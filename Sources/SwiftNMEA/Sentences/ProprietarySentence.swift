/// 7.3.6 Proprietary sentences
///
/// These are sentences not included within this standard; these provide a means
/// for manufacturers to use the sentence structure definitions of this standard to
/// transfer data which does not fall within the scope of approved sentences. This
/// will generally be for one of the following reasons:
///
/// * data is intended for another device from the same manufacturer, is device
///   specific, and not in a form or of a type of interest to the general user;
/// * data is being used for test purposes prior to the adoption of approved
///   sentences;
/// * data is not of a type and general usefulness which merits the creation of an
///   approved sentence.
///
/// Details of proprietary data fields are not included in this standard and need
/// not be submitted for approval. However, it is required that such sentences be
/// published in the manufacturer’s manuals for reference.
public struct ProprietarySentence: Sentence, Element, Sendable, Codable, Equatable {
  private static let parser = ProprietaryParser()

  public var delimiter: Delimiter { .parametric }

  /// It is recommended to use ``manufacturer`` and ``data`` instead of this
  /// instance variable.
  public var fields: Fields { .init(data: "P\(manufacturer)\(data)") }

  public let checksum: UInt8

  /// Manufacturer's mnemonic code (The NMEA secretariat maintains the master
  /// reference list which comprises codes registered and formally adopted by
  /// NMEA)
  public let manufacturer: String

  /// Manufacturer's data
  public let data: String

  public init?(sentence: String, ignoreChecksum: Bool = false) async throws {
    guard let result = try await Self.parser.parse(sentence: sentence) else { return nil }
    manufacturer = result.manufacturer
    data = result.data
    checksum = result.checksum

    guard ignoreChecksum || checksumIsValid else {
      throw NMEAError(type: .wrongChecksum, line: rawValue, value: checksumString)
    }
  }

  /// Creates a new instance from the given fields. The checksum is
  /// calculated automatically.
  public init(manufacturer: String, data: String) {
    self.manufacturer = manufacturer
    self.data = data
    checksum = Fields(data: "P\(manufacturer)\(data)").checksum
  }
}
