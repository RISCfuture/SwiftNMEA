// swiftlint:disable:next missing_docs
public struct NavigationStatus {
  private init() {}

  /**
   Integrity status of a navigational data item, as reported by the `NSR`
   sentence.

   Indicates whether the reporting device was able to verify the integrity of
   the associated data item, and the result of that verification.

   - SeeAlso: ``Message/Payload-swift.enum/navigationStatusReport(headingIntegrity:headingPlausibility:positionIntegrity:positionPlausibility:STWIntegrity:STWPlausibility:SOGCOGIntegrity:SOGCOGPlausibility:depthIntegrity:depthPlausibility:STWMode:timeIntegrity:timePlausibility:)``
   */
  public enum Integrity: Character, Sendable, Codable, Equatable {

    /// Passed, integrity verification passed.
    case passed = "P"

    /// Failed, integrity verification not passed.
    case failed = "F"

    /// Doubtful, integrity verification not possible.
    case doubtful = "D"

    /// Not available, reporting device does not support integrity check.
    case unavailable = "N"
  }

  /**
   Plausibility status of a navigational data item, as reported by the `NSR`
   sentence.

   Indicates whether the reporting device considers the associated data item to
   be plausible.

   - SeeAlso: ``Message/Payload-swift.enum/navigationStatusReport(headingIntegrity:headingPlausibility:positionIntegrity:positionPlausibility:STWIntegrity:STWPlausibility:SOGCOGIntegrity:SOGCOGPlausibility:depthIntegrity:depthPlausibility:STWMode:timeIntegrity:timePlausibility:)``
   */
  public enum Plausibility: Character, Sendable, Codable, Equatable {

    /// Yes (plausible).
    case plausible = "A"

    /// No (not plausible).
    case notPlausible = "V"

    /// Not available, reporting device does not support plausibility check.
    case unavailable = "N"
  }

  /**
   Mode of speed through water (STW), as reported by the `NSR` sentence.

   - SeeAlso: ``Message/Payload-swift.enum/navigationStatusReport(headingIntegrity:headingPlausibility:positionIntegrity:positionPlausibility:STWIntegrity:STWPlausibility:SOGCOGIntegrity:SOGCOGPlausibility:depthIntegrity:depthPlausibility:STWMode:timeIntegrity:timePlausibility:)``
   */
  public enum STWMode: Character, Sendable, Codable, Equatable {

    /// Measured water reference.
    case measured = "W"

    /// Estimated/calculated from non-water referenced sources.
    case estimated = "E"

    /// Manual input.
    case manual = "M"

    /// Not available.
    case unavailable = "N"
  }
}
