import Foundation

extension UnitPressure {
  private static let atm = 101_325.0

  /// Pascals (Pa): SI unit of pressure
  public static let pascals = UnitPressure(
    symbol: "Pa",
    converter: UnitConverterLinear(coefficient: 1)
  )

  /// Atmospheres (atm): Pressure of the standard atmosphere at sea level
  public static let atmosphere = UnitPressure(
    symbol: "atm",
    converter: UnitConverterLinear(coefficient: atm)
  )

  /// Torr: Approximately equal to 1mm of mercury
  public static let torr = UnitPressure(
    symbol: "torr",
    converter: UnitConverterLinear(coefficient: atm / 760)
  )
}
