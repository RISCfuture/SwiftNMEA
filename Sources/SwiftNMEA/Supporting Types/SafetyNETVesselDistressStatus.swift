import Foundation

extension SafetyNET {

  /**
   The status of the distress case for a specific vessel in distress, carried by
   the `SMV` sentence (field 16, section 8.3.97 comment 12). The status applies
   to the vessel identified by the `SMV` Unique message number and the
   associated MMSI, vessel name, and position fields. This field is never null.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum VesselDistressStatus: Character, Sendable, Codable, Equatable {

    /// `D`: distress active.
    case distressActive = "D"

    /// `C`: distress cancelled.
    case distressCancelled = "C"
  }
}
