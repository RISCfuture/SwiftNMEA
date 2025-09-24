// swiftlint:disable:next missing_docs
public struct Heading {
  private init() {}

  /**
   Heading sensor modes.
  
   - SeeAlso: ``Message/Payload-swift.enum/trueHeadingMode(_:mode:)``
   */
  public enum Mode: Character, Sendable, Codable, Equatable {

    /// Autonomous
    case autonomous = "A"

    /// Estimated (dead reckoning)
    case estimated = "E"

    /// Manual input
    case manual = "M"

    /// Simulator mode
    case simulator = "S"

    /// Data not valid (including standby)
    case invalid = "V"
  }
}
