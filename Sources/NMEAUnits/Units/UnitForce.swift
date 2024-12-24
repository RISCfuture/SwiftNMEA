import Foundation

/**
 A force is an influence that can cause an object to change its velocity unless
 counterbalanced by other forces. The concept of force makes the everyday notion
 of pushing or pulling mathematically precise. Because the magnitude and
 direction of a force are both important, force is a vector quantity.
 */
@preconcurrency
public class UnitForce: Dimension, @unchecked Sendable {

    /// Newtons (N): SI unit of force, the force that accelerates a mass of 1 kg at 1 m/s^2
    public static let newtons = UnitForce(symbol: "N", converter: UnitConverterLinear(coefficient: 1))

    /// Kilonewtons (kN)
    public static let kilonewtons = UnitForce(symbol: "kN", converter: UnitConverterLinear(coefficient: 1000))

    /// Meganewtons (MN)
    public static let meganewtons = UnitForce(symbol: "MN", converter: UnitConverterLinear(coefficient: 1_000_000))

    /// Dynes (dyn): CGS unit of force
    public static let dynes = UnitForce(symbol: "dyn", converter: UnitConverterLinear(coefficient: 1 / 100_000.0))

    /// Pounds force (lbf): American standard unit of force
    public static let pounds: UnitForce = unit(UnitMass.pounds, times: UnitAcceleration.gravity, symbol: "lbf")

    /// Ounces force (ozf)
    public static let ounces: UnitForce = unit(UnitMass.ounces, times: UnitAcceleration.gravity, symbol: "ozf")

    /// Tons (short) force (tnf)
    public static let shortTons: UnitForce = unit(UnitMass.shortTons, times: UnitAcceleration.gravity, symbol: "tnf")

    /// Kiloponds (kp): kilogram force
    public static let kiloponds: UnitForce = unit(UnitMass.kilograms, times: UnitAcceleration.gravity, symbol: "kp")

    override public class func baseUnit() -> Self { newtons as! Self }
}
