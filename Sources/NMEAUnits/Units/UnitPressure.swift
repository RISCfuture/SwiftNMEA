import Foundation

public extension UnitPressure {
    private static let atm = 101_325.0

    /// Pascals (Pa): SI unit of pressure
    static let pascals = UnitPressure(symbol: "Pa", converter: UnitConverterLinear(coefficient: 1))

    /// Atmospheres (atm): Pressure of the standard atmosphere at sea level
    static let atmosphere = UnitPressure(symbol: "atm", converter: UnitConverterLinear(coefficient: atm))

    /// Torr: Approximately equal to 1mm of mercury
    static let torr = UnitPressure(symbol: "torr", converter: UnitConverterLinear(coefficient: atm / 760))
}
