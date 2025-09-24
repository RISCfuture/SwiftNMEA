import Foundation
import NMEACommon

/// 2.1.2.1 - Enhanced position resolution
///
/// - SeeAlso: ``Message/enhancedPositionResolution(_:)``
public struct PositionEnhancement: RawRepresentable, Sendable, Codable, Equatable {

  /// The fractional component of the minutes portion of a latitude, up
  /// to four digits (10,000ths place).
  public let latitudeRefinement: Measurement<UnitAngle>

  /// The fractional component of the minutes portion of a longitude, up
  /// to four digits (10,000ths place).
  public let longitudeRefinement: Measurement<UnitAngle>

  public var rawValue: String {
    let latMin = latitudeRefinement.converted(to: .arcMinutes).value
    let lonMin = longitudeRefinement.converted(to: .arcMinutes).value
    let latStr = String(format: "%04d", latMin * 10000)
    let lonStr = String(format: "%04d", lonMin * 1000)
    return "\(latStr)\(lonStr)"
  }

  public init?(rawValue: String) {
    guard ("00000000"..."99999999").contains(rawValue) else { return nil }

    let latStr = rawValue.slice(from: 0, to: 3)
    let lonStr = rawValue.slice(from: 4, to: 7)
    guard let lat = Int(latStr), let lon = Int(lonStr) else { return nil }
    latitudeRefinement = .init(value: Double(lat) / 10000, unit: .arcMinutes)
    longitudeRefinement = .init(value: Double(lon) / 10000, unit: .arcMinutes)
  }

  /**
   Refines a latitude and longitude given the refinement data contained in
   this message. Returns the refined position.
  
   - Parameter position: The position to refine. Altitude is unchanged.
   - Returns: The refined position.
   */
  public func refine(position: Position) -> Position {
    let refinedLat = position.latitude.refine(latitudeRefinement)
    let refinedLon = position.longitude.refine(longitudeRefinement)
    return .init(latitude: refinedLat, longitude: refinedLon, altitude: position.altitude)
  }
}
