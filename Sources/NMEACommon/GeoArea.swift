import Foundation

/// A geographic reference area, used by DSC, as defined in ITU-R M.493-16.
public struct GeoArea: Sendable, Codable, Equatable {

  /// The latitude of the reference point
  public let latitude: Measurement<UnitAngle>

  /// The longitude of the reference point
  public let longitude: Measurement<UnitAngle>

  /// The vertical (i.e. North-to-South) side of the rectangle, Δφ
  public let deltaLat: Measurement<UnitAngle>

  /// The horizontal (i.e. West-to-East) side of the rectangle, Δλ
  public let deltaLon: Measurement<UnitAngle>

  public init(
    latitude: Measurement<UnitAngle>,
    longitude: Measurement<UnitAngle>,
    deltaLat: Measurement<UnitAngle>,
    deltaLon: Measurement<UnitAngle>
  ) {
    self.latitude = latitude
    self.longitude = longitude
    self.deltaLat = deltaLat
    self.deltaLon = deltaLon
  }

  public init(latitude: Double, longitude: Double, deltaLat: Double, deltaLon: Double) {
    self.init(
      latitude: .init(value: latitude, unit: .degrees),
      longitude: .init(value: longitude, unit: .degrees),
      deltaLat: .init(value: deltaLat, unit: .degrees),
      deltaLon: .init(value: deltaLon, unit: .degrees)
    )
  }

  public init(northeast: Position, southwest: Position) {
    let deltaLat = southwest.latitude - northeast.latitude
    let deltaLon = southwest.longitude - northeast.longitude

    self.init(
      latitude: southwest.latitude,
      longitude: southwest.longitude,
      deltaLat: deltaLat,
      deltaLon: deltaLon
    )
  }
}
