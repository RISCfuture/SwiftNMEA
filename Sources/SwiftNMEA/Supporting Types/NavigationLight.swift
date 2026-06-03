import Foundation

/**
 The reported status of a single navigation light, as carried by an `NLS`
 (navigation light status) sentence.

 Each `NLS` sentence carries a variable number of these reports, identified
 by their ``identifier``.

 - SeeAlso: ``Message/Payload-swift.enum/navigationLightStatus(id:lights:)``
 */
public struct NavigationLight: Sendable, Codable, Equatable {

  /**
   The assigned numeric identifier for this navigation light within the
   sentence. The assignment and configuration of light numeric identifiers
   are typically defined or configured within the navigation lights
   controller.
   */
  public let identifier: UInt

  /**
   The current known status for the navigation light, or `nil` if the status
   is not known (the status field was null).
   */
  public let status: Status?

  /**
   An estimate of the remaining working hours of the navigation light, or
   `nil` if the estimate is not known (the field was null). Remaining working
   hours may not be supported by the navigation light controller.
   */
  public let remainingWorkingHours: RemainingWorkingHours?

  public init(identifier: UInt, status: Status?, remainingWorkingHours: RemainingWorkingHours?) {
    self.identifier = identifier
    self.status = status
    self.remainingWorkingHours = remainingWorkingHours
  }

  /**
   The current known status for a reported navigation light. Not all status
   values are required to be supported by the navigation light controller.

   - SeeAlso: ``Message/Payload-swift.enum/navigationLightStatus(id:lights:)``
   */
  public enum Status: Int, Sendable, Codable, Equatable {

    /// Light not in use.
    case notInUse = 0

    /// Light is off.
    case off = 1

    /// Light is on.
    case on = 2

    /// Light has error: reason unknown.
    case errorUnknown = 3

    /// Light has error: short circuit.
    case errorShortCircuit = 4

    /// Light has error: open circuit.
    case errorOpenCircuit = 5

    /// Light has error: low luminosity.
    case errorLowLuminosity = 6

    /// Light has error: other.
    case errorOther = 9
  }

  /**
   An estimate of the remaining working hours of a navigation light. The
   underlying field is expressed in units of 100 h.

   - SeeAlso: ``Message/Payload-swift.enum/navigationLightStatus(id:lights:)``
   */
  public enum RemainingWorkingHours: Sendable, Codable, Equatable {

    /**
     An estimate of remaining time, derived from a field value of 0 to 98 in
     units of 100 h. For example, a field value of 27 indicates 2 700 h
     estimated remaining working hours.
     */
    case estimate(Measurement<UnitDuration>)

    /**
     An estimate of remaining time of more than 9 800 h, signalled by a field
     value of 99.
     */
    case moreThan9800Hours

    /**
     Creates an estimate from the raw `NLS` field value, which is in units of
     100 h.

     - Parameter rawValue: The field value, 0 to 99. Returns `nil` for any
       other value.
     */
    public init?(rawValue: UInt) {
      switch rawValue {
        case 0...98: self = .estimate(.init(value: Double(rawValue) * 100, unit: .hours))
        case 99: self = .moreThan9800Hours
        default: return nil
      }
    }
  }
}
