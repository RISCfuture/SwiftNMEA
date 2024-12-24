import Foundation
import NMEACommon

/**
 An accuracy enhancement to a geographical area.

 - SeeAlso: ``Message/enhnancedGeoArea(_:)``
 */
public struct GeoAreaEnhancement: RawRepresentable, Sendable, Codable, Equatable {
    public typealias RawValue = String

    /// The arc-minutes of the latitude, to the hundredths place.
    public let latitudeRefinement: Measurement<UnitAngle>

    /// The arc-minutes of the longitude, to the hundredths place.
    public let longitudeRefinement: Measurement<UnitAngle>

    /// The arc-minutes of the vertical extension, to the hundredths place.
    public let deltaLatRefinement: Measurement<UnitAngle>

    /// The arc-minutes of the horizontal extension, to the hundredths place.
    public let deltaLonRefinement: Measurement<UnitAngle>

    /// The current vessel course, in degrees, to the tenths place.
    public let course: Measurement<UnitAngle>

    /// The current vessel speed, in knots, to the tenths place.
    public let speed: Measurement<UnitSpeed>

    public var rawValue: String {
        let latMin = latitudeRefinement.converted(to: .arcMinutes).value,
            lonMin = longitudeRefinement.converted(to: .arcMinutes).value,
            deltaLatMin = deltaLatRefinement.converted(to: .arcMinutes).value,
            deltaLonMin = deltaLonRefinement.converted(to: .arcMinutes).value,
            latStr = String(format: "%04.0f", latMin * 100),
            lonStr = String(format: "%04.0f", lonMin * 100),
            latDeltaStr = String(format: "%04.0f", deltaLatMin * 100),
            lonDeltaStr = String(format: "%04.0f", deltaLonMin * 100),
            courseStr = String(format: "%04.0f", course.converted(to: .degrees).value * 10),
            speedStr = String(format: "%04.0f", speed.converted(to: .knots).value * 10)

        return "\(latStr)\(lonStr)\(latDeltaStr)\(lonDeltaStr)\(courseStr)\(speedStr)"
    }

    // TODO: how to handle command character 126 in course or speed?
    public init?(rawValue: String) {
        guard (String(repeating: "0", count: 24)...String(repeating: "9", count: 24)).contains(rawValue) else {
            return nil
        }

        let latStr = rawValue.slice(from: 0, to: 3),
            lonStr = rawValue.slice(from: 4, to: 7),
            latDeltaStr = rawValue.slice(from: 8, to: 11),
            lonDeltaStr = rawValue.slice(from: 12, to: 15),
            speedStr = rawValue.slice(from: 16, to: 19),
            courseStr = rawValue.slice(from: 20, to: 23)

        guard let latValue = Int(latStr), let lonValue = Int(lonStr),
              let latDeltaValue = Int(latDeltaStr), let lonDeltaValue = Int(lonDeltaStr),
              let courseValue = Int(courseStr), let speedValue = Int(speedStr) else {
            return nil
        }

        latitudeRefinement = .init(value: Double(latValue) / 100, unit: .arcMinutes)
        longitudeRefinement = .init(value: Double(lonValue) / 100, unit: .arcMinutes)
        deltaLatRefinement = .init(value: Double(latDeltaValue) / 100, unit: .arcMinutes)
        deltaLonRefinement = .init(value: Double(lonDeltaValue) / 100, unit: .arcMinutes)
        course = .init(value: Double(courseValue) / 10, unit: .degrees)
        speed = .init(value: Double(speedValue) / 10, unit: .knots)
    }

    /**
     Refines a geographical area with the enhancement data in the receiver.

     - Parameter area: The geographical area to refine.
     - Returns: A new `GeoArea` with latitude, longtiude, Δφ, and Δλ refined.
     **/
    public func refine(area: GeoArea) -> GeoArea {
        .init(latitude: area.latitude.refine(latitudeRefinement),
              longitude: area.longitude.refine(longitudeRefinement),
              deltaLat: area.deltaLat.refine(deltaLatRefinement),
              deltaLon: area.deltaLon.refine(deltaLonRefinement))
    }
}
