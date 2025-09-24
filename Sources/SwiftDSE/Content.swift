/// The content of a ``Message``, which can either be ``data(_:)`` or a command
/// character as defined in Rec. ITU-R M.821-1, table 3.
public enum Content<Data>: RawRepresentable where Data: RawRepresentable, Data.RawValue == String {
  public typealias RawValue = String

  /// Available data.
  case data(_ data: Data)

  /// A data request command.
  case dataRequest

  /// No enhancement data available.
  case noDataAvailable

  public var rawValue: String {
    switch self {
      case .data(let data): data.rawValue
      case .dataRequest: "C10"
      case .noDataAvailable: "C26"
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
      case "C10": self = .dataRequest
      case "C26": self = .noDataAvailable
      default:
        guard let data = Data(rawValue: rawValue) else { return nil }
        self = .data(data)
    }
  }

  static func nilPlaceholder(isQuery: Bool) -> Self {
    isQuery ? .dataRequest : .noDataAvailable
  }
}

extension Content: Sendable where Data: Sendable {}
extension Content: Codable where Data: Codable {}
extension Content: Equatable where Data: Equatable {}
