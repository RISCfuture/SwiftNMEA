import Foundation

final class PackedBinaryCoder: Sendable {
  /// Decodes a sequence of packed binary fields into a sparse map from each
  /// field’s relative offset to its decoded bytes.
  ///
  /// Each field is a fixed 4-character HEX value representing one 16-bit
  /// entity. A `nil` field is a “no update” (null) entity: it advances the
  /// offset but produces no entry in the returned map. A present-but-malformed
  /// field throws ``Errors/invalidChunk(index:)``.
  ///
  /// - Parameter value: The packed binary fields, in order, with `nil` for
  ///   null fields.
  /// - Returns: A map from each non-null field’s zero-based offset to its
  ///   decoded bytes.
  /// - Throws: ``Errors/invalidChunk(index:)`` if a non-null field is not a
  ///   valid 4-character HEX value.
  func decodeEntities(_ value: some Sequence<String?>) throws(Errors) -> [Int: Data] {
    var entities = [Int: Data]()
    for chunk in value.enumerated() {
      guard let element = chunk.element else { continue }  // null field: no update
      entities[chunk.offset] = try decode([element], offsetBy: chunk.offset)
    }
    return entities
  }

  func decode(_ value: some Sequence<String>, offsetBy offset: Int = 0) throws(Errors) -> Data {
    var bytes = [UInt8]()
    for chunk in value.enumerated() {
      switch chunk.element.count {
        case 2:
          guard let byte = UInt8(chunk.element, radix: 16) else {
            throw .invalidChunk(index: chunk.offset + offset)
          }
          bytes.append(byte)

        case 4:
          let highStr = chunk.element.prefix(2)
          let lowStr = chunk.element.suffix(2)
          guard let high = UInt8(highStr, radix: 16),
            let low = UInt8(lowStr, radix: 16)
          else {
            throw .invalidChunk(index: chunk.offset + offset)
          }
          bytes.append(high)
          bytes.append(low)

        default:
          throw .invalidChunk(index: chunk.offset + offset)
      }
    }

    return Data(bytes)
  }

  enum Errors: Error {
    case invalidChunk(index: Int)
  }
}
