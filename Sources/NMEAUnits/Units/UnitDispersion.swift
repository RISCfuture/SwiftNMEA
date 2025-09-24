import Foundation

extension UnitDispersion {

  /// Pascals (Pa): SI unit of pressure
  public static let partsPerThousand = UnitDispersion(
    symbol: "ppt",
    converter: UnitConverterLinear(coefficient: 1000)
  )
}
