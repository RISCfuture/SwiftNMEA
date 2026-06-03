import Foundation

extension SafetyNET {

  /**
   The fixed two-digit Service code identifying the type of MSI message carried
   by an `SM1` sentence (field 7, section 8.3.92 comment 7). `SM1` reports MSI
   messages addressed to all ships, so only the service codes `00` and `31` are
   valid here; for any other service code the field is a null field, which this
   library models as `nil`.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum AllShipsServiceCode: Int, Sendable, Codable, Equatable {

    /// `00`: All ships (general call).
    case allShips = 0

    /// `31`: NAVAREA/METAREA warning, MET Forecast, or Piracy warning to a
    /// NAVAREA/METAREA.
    case navAreaWarning = 31
  }
}
