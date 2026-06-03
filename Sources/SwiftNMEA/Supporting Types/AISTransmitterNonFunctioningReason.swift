import Foundation

extension AIS {

  /**
   The reason an AIS class A station was not transmitting position reports,
   as reported in a `TRL` log entry.

   - SeeAlso: ``Message/Payload-swift.enum/AISTransmitterNonFunctioningLog(id:entries:)``
   */
  public enum TransmitterNonFunctioningReason: Int, Sendable, Codable, Equatable {

    /// Power off.
    case powerOff = 1

    /// Silent mode.
    case silentMode = 2

    /// Transmission switched off by channel management command.
    case switchedOffByChannelManagement = 3

    /// Equipment malfunction.
    case equipmentMalfunction = 4

    /// Invalid configuration.
    case invalidConfiguration = 5

    /// Reserved for future use (value 6).
    case reserved6 = 6

    /// Reserved for future use (value 7).
    case reserved7 = 7

    /// Reserved for future use (value 8).
    case reserved8 = 8

    /// Reserved for future use (value 9).
    case reserved9 = 9
  }
}
