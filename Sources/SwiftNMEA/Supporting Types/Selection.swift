// swiftlint:disable:next missing_docs
public struct Selection {
  private init() {}

  /**
   The type of data referenced by a data selection pair in the `SEL`
   sentence.

   Identifies which kind of navigational data a selection applies to, for
   example a selection published by a consistent common reference system
   (CCRS) associated with an integrated navigation system (INS).

   - SeeAlso: ``Message/Payload-swift.enum/dataSelection(_:)``
   */
  public enum DataID: String, Sendable, Codable, Equatable {

    /// Position.
    case position = "POS"

    /// Speed and course over ground.
    case speedCourseOverGround = "SOG"

    /// Speed through water.
    case speedThroughWater = "STW"

    /// Depth below keel.
    case depthBelowKeel = "DEP"

    /// Heading.
    case heading = "HEA"

    /// Time.
    case time = "TIM"
  }
}
