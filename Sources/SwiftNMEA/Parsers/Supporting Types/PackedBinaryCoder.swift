import Foundation

final class PackedBinaryCoder: Sendable {
    func encode(_ value: Data) -> [String] {
        value.chunks(ofCount: 2).map { chunk in
            if let high = chunk.first, let low = chunk.last {
                String(format: "%02X%02X", high, low)
            } else if let high = chunk.first {
                String(format: "%02X%02X", high, 0)
            } else {
                fatalError("Expected chunks of 2 bytes")
            }
        }
    }

    func decode(_ value: some Sequence<String>) throws -> Data {
        let bytes = try value.enumerated().reduce(into: [UInt8]()) { data, chunk in
            switch chunk.element.count {
                case 2:
                    guard let byte = UInt8(chunk.element, radix: 16) else {
                        throw Errors.invalidChunk(index: chunk.offset)
                    }
                    data.append(byte)

                case 4:
                    let highStr = chunk.element.prefix(2), lowStr = chunk.element.suffix(2)
                    guard let high = UInt8(highStr, radix: 16),
                          let low = UInt8(lowStr, radix: 16) else {
                        throw Errors.invalidChunk(index: chunk.offset)
                    }
                    data.append(high)
                    data.append(low)

                default:
                    throw Errors.invalidChunk(index: chunk.offset)
            }
        }

        return Data(bytes)
    }

    enum Errors: Error {
        case invalidChunk(index: Int)
    }
}
