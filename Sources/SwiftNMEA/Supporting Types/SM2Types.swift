import Foundation

/**
 Types specific to the `SM2` sentence (SafetyNET Message, Coastal Warning Area;
 IEC 61162-1 ed.6.0 section 8.3.93). Shared SafetyNET concepts live under
 ``SafetyNET``; only the SM2-specific Service code and Coastal warning subject
 indicator are defined here.

 - SeeAlso: ``Message/Payload-swift.enum``
 */
public enum SM2 {

  /**
   The fixed two-digit Service code identifying the type of MSI message carried
   by an `SM2` sentence (field 7, section 8.3.93 comment 7). For `SM2` the only
   valid value corresponds to a coastal warning area. The field is set to a null
   field for all other Service Code values, so it is decoded as optional.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum ServiceCode: Int, Sendable, Codable, Equatable {

    /// `13`: Navigational, Meteorological, or Piracy Coastal warning.
    case coastalWarning = 13
  }

  /**
   The Coastal warning subject indicator (field 16, section 8.3.93 comment 16).
   A single alpha character, the fourth character of the transmitted message's
   `X1X2B1B2` coastal warning area address. The meanings are defined in the
   GMDSS Master plan (IMO `GMDSS.1/Circ.18`). This field is null if the subject
   indicator was received in error or if the Service Code is not `13`, so it is
   decoded as optional.

   - SeeAlso: ``Message/Payload-swift.enum``
   */
  public enum CoastalWarningSubject: Character, Sendable, Codable, Equatable {

    /// `A`: Navigational warnings.
    case navigationalWarnings = "A"

    /// `B`: Meteorological warnings.
    case meteorologicalWarnings = "B"

    /// `C`: Ice reports.
    case iceReports = "C"

    /// `D`: Search and rescue information, and acts of piracy warnings.
    case searchAndRescue = "D"

    /// `E`: Meteorological forecasts.
    case meteorologicalForecasts = "E"

    /// `F`: Pilot service messages.
    case pilotService = "F"

    /// `G`: AIS.
    case AIS = "G"

    /// `H`: LORAN messages.
    case LORAN = "H"

    /// `J`: SATNAV messages.
    case SATNAV = "J"

    /// `K`: Other electronic navaid messages.
    case otherElectronicNavaid = "K"

    /// `L`: Other Navigational warnings – additional to subject indicator code
    /// (c2) of `A`.
    case otherNavigationalWarnings = "L"

    /// `V`: Special services allocation by the International SafetyNET Panel.
    case specialServicesV = "V"

    /// `W`: Special services allocation by the International SafetyNET Panel.
    case specialServicesW = "W"

    /// `X`: Special services allocation by the International SafetyNET Panel.
    case specialServicesX = "X"

    /// `Y`: Special services allocation by the International SafetyNET Panel.
    case specialServicesY = "Y"

    /// `Z`: No messages on hand.
    case noMessages = "Z"
  }
}
