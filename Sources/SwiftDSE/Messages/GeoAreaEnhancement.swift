import Foundation
import NMEACommon

/// An accuracy enhancement to a geographical area.
///
/// - SeeAlso: ``Message/enhnancedGeoArea(_:)``
public struct GeoAreaEnhancement: RawRepresentable, Sendable, Codable, Equatable {
  public typealias RawValue = String

  /// Emitted in place of a speed or course sub-field when no estimate is
  /// available. ITU-R M.821-1 §2.1.2.6 specifies "two symbols No. 126" for this
  /// case, but its exact NMEA-character encoding is not given by the freely
  /// available specifications. A non-numeric placeholder is therefore written,
  /// and on decode any non-numeric sub-field is mapped back to `nil`.
  private static let noDataSentinel = "----"

  /// The arc-minutes of the latitude, to the hundredths place.
  public let latitudeRefinement: Measurement<UnitAngle>

  /// The arc-minutes of the longitude, to the hundredths place.
  public let longitudeRefinement: Measurement<UnitAngle>

  /// The arc-minutes of the vertical extension, to the hundredths place.
  public let deltaLatRefinement: Measurement<UnitAngle>

  /// The arc-minutes of the horizontal extension, to the hundredths place.
  public let deltaLonRefinement: Measurement<UnitAngle>

  /// The current vessel speed, in knots, to the tenths place, or `nil` if no
  /// speed estimate is available (ITU-R M.821-1 §2.1.2.6).
  public let speed: Measurement<UnitSpeed>?

  /// The current vessel course, in degrees, to the tenths place, or `nil` if no
  /// course estimate is available (ITU-R M.821-1 §2.1.2.6).
  public let course: Measurement<UnitAngle>?

  public var rawValue: String {
    let latMin = latitudeRefinement.converted(to: .arcMinutes).value
    let lonMin = longitudeRefinement.converted(to: .arcMinutes).value
    let deltaLatMin = deltaLatRefinement.converted(to: .arcMinutes).value
    let deltaLonMin = deltaLonRefinement.converted(to: .arcMinutes).value
    let latStr = String(format: "%04.0f", latMin * 100)
    let lonStr = String(format: "%04.0f", lonMin * 100)
    let latDeltaStr = String(format: "%04.0f", deltaLatMin * 100)
    let lonDeltaStr = String(format: "%04.0f", deltaLonMin * 100)
    let speedStr =
      speed.map { String(format: "%04.0f", $0.converted(to: .knots).value * 10) }
      ?? Self.noDataSentinel
    let courseStr =
      course.map { String(format: "%04.0f", $0.converted(to: .degrees).value * 10) }
      ?? Self.noDataSentinel

    return "\(latStr)\(lonStr)\(latDeltaStr)\(lonDeltaStr)\(speedStr)\(courseStr)"
  }

  public init?(rawValue: String) {
    guard rawValue.count == 24 else { return nil }

    let latStr = rawValue.slice(from: 0, to: 3)
    let lonStr = rawValue.slice(from: 4, to: 7)
    let latDeltaStr = rawValue.slice(from: 8, to: 11)
    let lonDeltaStr = rawValue.slice(from: 12, to: 15)
    let speedStr = rawValue.slice(from: 16, to: 19)
    let courseStr = rawValue.slice(from: 20, to: 23)

    guard let latValue = Int(latStr), let lonValue = Int(lonStr),
      let latDeltaValue = Int(latDeltaStr), let lonDeltaValue = Int(lonDeltaStr),
      latValue >= 0, lonValue >= 0, latDeltaValue >= 0, lonDeltaValue >= 0
    else {
      return nil
    }

    latitudeRefinement = .init(value: Double(latValue) / 100, unit: .arcMinutes)
    longitudeRefinement = .init(value: Double(lonValue) / 100, unit: .arcMinutes)
    deltaLatRefinement = .init(value: Double(latDeltaValue) / 100, unit: .arcMinutes)
    deltaLonRefinement = .init(value: Double(lonDeltaValue) / 100, unit: .arcMinutes)

    // Speed and course are independently optional: a sub-field of "two symbols
    // No. 126" (ITU-R M.821-1 §2.1.2.6) means no estimate is available.
    speed = Self.measurement(from: speedStr, unit: .knots)
    course = Self.measurement(from: courseStr, unit: .degrees)
  }

  private static func measurement<UnitType>(
    from field: some StringProtocol,
    unit: UnitType
  ) -> Measurement<UnitType>? where UnitType: Unit {
    guard let tenths = Int(field), tenths >= 0 else { return nil }
    return .init(value: Double(tenths) / 10, unit: unit)
  }

  /**
   Refines a geographical area with the enhancement data in the receiver.

   - Parameter area: The geographical area to refine.
   - Returns: A new `GeoArea` with latitude, longtiude, Δφ, and Δλ refined.
   **/
  public func refine(area: GeoArea) -> GeoArea {
    .init(
      latitude: area.latitude.refine(latitudeRefinement),
      longitude: area.longitude.refine(longitudeRefinement),
      deltaLat: area.deltaLat.refine(deltaLatRefinement),
      deltaLon: area.deltaLon.refine(deltaLonRefinement)
    )
  }
}
