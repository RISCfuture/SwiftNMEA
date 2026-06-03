import Foundation

extension AIS {

  /**
   A single entry in an AIS class A station's transmitter-non-functioning log,
   as reported by a `TRL` sentence (IEC 61162-1 ed.6.0 (2024) 8.3.106). Each
   entry records one period of more than 15 minutes during which the unit was
   not transmitting position reports (e.g. the unit was switched off or the
   transmitter was inactivated).

   - SeeAlso: ``Message/Payload-swift.enum/AISTransmitterNonFunctioningLog(id:entries:)``
   */
  public struct TransmitterNonFunctioningLogEntry: Sendable, Codable, Equatable {

    /// The log entry number, identifying this specific log entry. Ranges from
    /// `1` to the total number of log entries.
    public let number: Int

    /// The UTC date and time at which the transmitter was switched off. The
    /// required resolution is in minutes.
    public let switchOff: Date

    /// The UTC date and time at which the transmitter was switched on. The
    /// required resolution is in minutes.
    public let switchOn: Date

    /// The reason the transmitter was not functioning.
    public let reason: TransmitterNonFunctioningReason

    public init(
      number: Int,
      switchOff: Date,
      switchOn: Date,
      reason: TransmitterNonFunctioningReason
    ) {
      self.number = number
      self.switchOff = switchOff
      self.switchOn = switchOn
      self.reason = reason
    }
  }
}
