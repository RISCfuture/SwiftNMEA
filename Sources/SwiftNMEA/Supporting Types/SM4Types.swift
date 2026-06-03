import Foundation

/**
 Namespace for types specific to the `SM4` sentence (SafetyNET Message,
 Rectangular Area Address; section 8.3.95). Shared SafetyNET concepts live under
 ``SafetyNET``; this namespace holds only the values whose valid set is unique to
 `SM4`.

 - SeeAlso: ``Message/Payload-swift.enum``
 */
public enum SM4 {

  /**
   The fixed two-digit Service code identifying the type of MSI message carried
   by an `SM4` sentence (field 7, section 8.3.95 comment 7). `SM4` reports MSI
   messages addressed to a rectangular area, so only the service codes `04` and
   `34` are valid here; for any other service code the field is a null field,
   which this library models as `nil`.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum ServiceCode: Int, Sendable, Codable, Equatable {

    /// `04`: Navigational, Meteorological, or Piracy warning to a rectangular
    /// area.
    case navigationalWarning = 4

    /// `34`: SAR Coordination to a rectangular area.
    case searchAndRescueCoordination = 34
  }
}
