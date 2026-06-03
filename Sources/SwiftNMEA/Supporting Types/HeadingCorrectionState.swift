extension Heading {

  /**
   The state of a heading correction reported by the `HCR` sentence.

   Indicates which corrections, if any, have been applied to the heading value
   produced by the heading source.

   - SeeAlso: ``Message/Payload-swift.enum/headingCorrectionReport(_:mode:correctionState:correctionValue:)``
   */
  public enum CorrectionState: Character, Sendable, Codable, Equatable {

    /// Both speed/latitude and dynamic correction included in heading
    case speedLatitudeAndDynamic = "A"

    /// Dynamic correction included in heading
    case dynamic = "D"

    /// Speed/latitude correction included in heading
    case speedLatitude = "S"

    /// No correction included in heading
    case noCorrection = "N"

    /// Not available, reporting device does not know about correction state
    case unavailable = "V"
  }
}
