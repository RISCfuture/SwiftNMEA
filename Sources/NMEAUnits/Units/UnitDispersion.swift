import Foundation

public extension UnitDispersion {

    /// Pascals (Pa): SI unit of pressure
    static let partsPerThousand = UnitDispersion(symbol: "ppt", converter: UnitConverterLinear(coefficient: 1000))
}
