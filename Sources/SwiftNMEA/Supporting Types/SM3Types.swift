import Foundation

/**
 Types specific to the `SM3` sentence (SafetyNET Message, Circular Area address;
 IEC 61162-1 ed.6.0 section 8.3.94). Shared SafetyNET concepts live under
 ``SafetyNET``; only the SM3-specific Service code is defined here.

 - SeeAlso: ``Message/Payload-swift.enum``
 */
public enum SM3 {

  /**
   The fixed two-digit Service code identifying the type of MSI message carried
   by an `SM3` sentence (field 7, section 8.3.94 comment 7). For `SM3` the valid
   values all correspond to a circular-area address. The field is set to a null
   field for all other Service Code values, so it is decoded as optional.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum ServiceCode: Int, Sendable, Codable, Equatable {

    /// `14`: Shore-to-Ship Distress Alert to a circular area.
    case distressAlert = 14

    /// `24`: Navigational, Meteorological, or Piracy warning to a circular
    /// area.
    case warning = 24

    /// `44`: SAR Coordination to a circular area.
    case searchAndRescueCoordination = 44
  }
}
