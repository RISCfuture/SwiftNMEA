import Foundation

/// Mass flow rate is the rate at which mass of a substance changes over time.
@preconcurrency
public class UnitFlow: Dimension, @unchecked Sendable {

    /// Cubic meters per second (m^3/s): SI unit of mass flow rate
    public static let cubicMetersPerSecond: UnitFlow = unit(UnitVolume.cubicMeters, per: UnitDuration.seconds)

    /// Liters per second (L/s)
    public static let litersPerSecond: UnitFlow = unit(UnitVolume.liters, per: UnitDuration.seconds)

    /// Liters per minute (LPM)
    public static let litersPerMinute: UnitFlow = unit(UnitVolume.liters, per: UnitDuration.minutes)

    /// Cubic meters per hour (m^3/hr)
    public static let cubicMetersPerHour: UnitFlow = unit(UnitVolume.cubicMeters, per: UnitDuration.hours)

    /// Milliliters per second (mL/s)
    public static let millilitersPerSecond: UnitFlow = unit(UnitVolume.milliliters, per: UnitDuration.seconds)

    /// Gallons per minute (GPM)
    public static let gallonsPerMinute: UnitFlow = unit(UnitVolume.gallons, per: UnitDuration.minutes, symbol: "GPM")

    /// Gallons per hour (GPH)
    public static let gallonsPerHour: UnitFlow = unit(UnitVolume.gallons, per: UnitDuration.hours, symbol: "GPH")

    /// Cubic feet per second (ft^3/s): American standard unit of mass flow rate
    public static let cubicFeetPerSecond: UnitFlow = unit(UnitVolume.cubicFeet, per: UnitDuration.seconds)

    /// Cubic feet per minute (CFM)
    public static let cubicFeetPerMinute: UnitFlow = unit(UnitVolume.cubicFeet, per: UnitDuration.minutes, symbol: "CFM")

    override public class func baseUnit() -> Self { litersPerSecond as! Self }
}
