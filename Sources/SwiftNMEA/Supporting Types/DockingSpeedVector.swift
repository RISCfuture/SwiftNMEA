import Foundation

/// A longitudinal docking speed referenced to a consistent common reference
/// point (CCRP), together with bow, CCRP, and stern transverse speeds.
///
/// - SeeAlso: ``Message/Payload-swift.enum/dockingSpeedData(water:waterValid:ground:groundValid:)``
public struct DockingSpeedVector: Sendable, Codable, Equatable {

  /// Longitudinal speed at the CCRP: "-" = astern.
  public let longitudinal: Measurement<UnitSpeed>

  /// Bow transverse speed: "-" = port.
  public let bowTransverse: Measurement<UnitSpeed>

  /// CCRP transverse speed: "-" = port.
  public let transverse: Measurement<UnitSpeed>

  /// Stern transverse speed: "-" = port.
  public let sternTransverse: Measurement<UnitSpeed>
}
