import Foundation

/// 7.3.3 Parametric sentences, 7.3.4 Encapsulated sentences
///
/// Reply or command messages consisting of multiple data fields. ``Message``s are
/// built from one or more parametric or encapsulated sentences.
public struct ParametricSentence: Sentence, Element, Sendable, Codable, Equatable {
  private static let parser = ParametricParser()

  public let delimiter: Delimiter
  public let fields: Fields
  public let checksum: UInt8

  /// The component that sent the message.
  public var talker: Talker { .init(rawValue: fields.address.sslice(to: 1))! }

  /// The message format.
  public var format: Format { .init(rawValue: fields.address.sslice(from: 2, to: 4))! }

  public init?(sentence: String, ignoreChecksum: Bool = false) async throws {
    guard let result = try await Self.parser.parse(sentence: sentence) else { return nil }
    delimiter = result.delimiter
    fields = .init(data: result.fields)
    checksum = result.checksum

    guard ignoreChecksum || checksumIsValid else {
      throw NMEAError(type: .wrongChecksum, line: rawValue, value: checksumString)
    }
  }

  /// Creates a new instance from the given fields. The checksum is
  /// calculated automatically.
  public init(delimiter: Delimiter, talker: Talker, format: Format, fields: [String?]) {
    self.delimiter = delimiter
    let fieldsObj = Fields(
      fields: ["\(talker.rawValue)\(format.rawValue)"] + fields.map { $0 ?? "" }
    )
    self.fields = fieldsObj
    checksum = fieldsObj.checksum
  }
}
