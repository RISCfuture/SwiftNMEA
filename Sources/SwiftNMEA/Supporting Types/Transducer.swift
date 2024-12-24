import Foundation
import NMEAUnits

// swiftlint:disable:next missing_docs
public struct Transducer {
    private init() {}

    /**
     A value measured from a transducer.

     - SeeAlso: ``Message/Payload-swift.enum/transducerMeasurements(_:)``
     */
    public enum Value: Sendable, Codable, Equatable {

        /// Temperature
        case temperature(_ value: Measurement<UnitTemperature>, id: String)

        /// Angular displacement. "-" = anticlockwise
        case angle(_ value: Measurement<UnitAngle>, id: String)

        /// Absolute humidity
        case absoluteHumidity(_ value: Measurement<UnitDensity>, id: String)

        /// Linear displacement. "-" = compression
        case displacement(_ value: Measurement<UnitLength>, id: String)

        /// Frequency
        case frequency(_ value: Measurement<UnitFrequency>, id: String)

        /// Salinity
        case salinity(_ value: Measurement<UnitDispersion>, id: String)

        /// Force. "-" = compression
        case force(_ value: Measurement<UnitForce>, id: String)

        /// Pressure. "-" = vacuum
        case pressure(_ value: Measurement<UnitPressure>, id: String)

        /// Flow rate
        case flowRate(_ value: Measurement<UnitFlow>, id: String)

        /// Tachometer
        case tachometer(_ value: Measurement<UnitAngularVelocity>, id: String)

        /// Humidity
        case relativeHumidity(_ value: Double, id: String)

        /// Volume
        case volume(_ value: Measurement<UnitVolume>, id: String)

        /// Voltage
        case electricPotential(_ value: Measurement<UnitElectricPotentialDifference>, id: String)

        /// Current
        case electricCurrent(_ value: Measurement<UnitElectricCurrent>, id: String)

        /// Switch or valve
        case boolean(_ value: Bool, id: String)

        /// Generic
        case generic(_ value: Double, id: String)
    }
}
