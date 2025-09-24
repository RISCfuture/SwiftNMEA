import Foundation

/// Angular velocity (ω) is a pseudovector representation of how the angular
/// position or orientation of an object changes with time, i.e. how quickly an
/// object rotates (spins or revolves) around an axis of rotation and how fast
/// the axis itself changes direction.
@preconcurrency
public class UnitAngularVelocity: Dimension, @unchecked Sendable {

  /// Radians per second (symbol: rad⋅s−1 or rad/s): SI unit of angular velocity
  public static let radiansPerSecond: UnitAngularVelocity = unit(
    UnitAngle.radians,
    per: UnitDuration.seconds
  )

  /// Revolutions per minute (RPM)
  public static let revolutionsPerMinute: UnitAngularVelocity = unit(
    UnitAngle.revolutions,
    per: UnitDuration.minutes,
    symbol: "RPM"
  )

  /// Degrees per minute (°/min)
  public static let degreesPerMinute: UnitAngularVelocity = unit(
    UnitAngle.degrees,
    per: UnitDuration.minutes
  )

  override public class func baseUnit() -> Self { radiansPerSecond as! Self }
}
