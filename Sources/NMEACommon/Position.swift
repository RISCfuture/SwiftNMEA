import Foundation

public struct Position: Codable, Sendable, Equatable, Hashable {
    public let latitude: Measurement<UnitAngle>
    public let longitude: Measurement<UnitAngle>
    public let altitude: Measurement<UnitLength>?

    package init(latitude: Double, longitude: Double, altitude: Double? = nil) {
        self.init(latitude: .init(value: latitude, unit: .degrees),
                  longitude: .init(value: longitude, unit: .degrees),
                  altitude: altitude != nil ? .init(value: altitude!, unit: .feet) : nil)
    }

    package init(latitude: (Int, Double), longitude: (Int, Double), altitude: Double? = nil) {
        let latDD = (abs(Double(latitude.0)) + latitude.1 / 60) * (latitude.0 >= 0 ? 1 : -1)
        let lonDD = (abs(Double(longitude.0)) + longitude.1 / 60) * (longitude.0 >= 0 ? 1 : -1)
        self.init(latitude: latDD, longitude: lonDD, altitude: altitude)
    }

    package init(latitude: Measurement<UnitAngle>, longitude: Measurement<UnitAngle>, altitude: Measurement<UnitLength>? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}
