import Foundation

/// Types related to man-over-board (MOB) monitoring systems.
public struct ManOverboard {
  private init() {}

  /**
   The current state of a MOB emitter, as reported in a `MOB` sentence.

   - SeeAlso: ``Message/Payload-swift.enum/manOverboard(emitterID:status:activationTime:positionSource:daysSinceActivation:positionTime:position:courseOverGround:speedOverGround:MMSI:batteryStatus:)``
   */
  public enum Status: Character, Sendable, Codable, Equatable {

    /// MOB activated.
    case activated = "A"

    /// Test mode.
    case test = "T"

    /// Manual button.
    case manualButton = "M"

    /// MOB not in use.
    case notInUse = "V"

    /// Error.
    case error = "E"
  }

  /**
   The source of the position information reported in a `MOB` sentence.

   - SeeAlso: ``Message/Payload-swift.enum/manOverboard(emitterID:status:activationTime:positionSource:daysSinceActivation:positionTime:position:courseOverGround:speedOverGround:MMSI:batteryStatus:)``
   */
  public enum PositionSource: Int, Sendable, Codable, Equatable {

    /// MOB position estimated by the vessel.
    case estimatedByVessel = 0

    /// MOB position reported by the MOB emitter.
    case reportedByEmitter = 1

    /// Error.
    case error = 6
  }

  /**
   The status of a MOB emitter's internal power source, as reported in a `MOB`
   sentence.

   - SeeAlso: ``Message/Payload-swift.enum/manOverboard(emitterID:status:activationTime:positionSource:daysSinceActivation:positionTime:position:courseOverGround:speedOverGround:MMSI:batteryStatus:)``
   */
  public enum BatteryStatus: Int, Sendable, Codable, Equatable {

    /// Good.
    case good = 0

    /// Low.
    case low = 1

    /// Error.
    case error = 6
  }
}
