import Foundation

/// In telecommunications and computing, bit rate (R) is the amount of data that
/// is conveyed or processed per unit of time.
@preconcurrency
public class UnitInformationTransferRate: Dimension, @unchecked Sendable {

  /// Bits per second (bps)
  public static let bitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.bits,
    per: UnitDuration.seconds
  )

  /// Bytes per second (Bps)
  public static let bytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.bytes,
    per: UnitDuration.seconds
  )

  /// Nibbles (half-bytes) per second
  public static let nibblesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.nibbles,
    per: UnitDuration.seconds
  )

  /// Yottabytes per second (YB/s)
  public static let yottabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.yottabytes,
    per: UnitDuration.seconds
  )

  /// Zettabytes per second (ZB/s)
  public static let zettabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.zettabytes,
    per: UnitDuration.seconds
  )

  /// Exabytes per second (EB/s)
  public static let exabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.exabytes,
    per: UnitDuration.seconds
  )

  /// Petabytes per second (PB/s)
  public static let petabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.petabytes,
    per: UnitDuration.seconds
  )

  /// Terabytes per second (TB/s)
  public static let terabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.terabytes,
    per: UnitDuration.seconds
  )

  /// Gigabytes per seocnd (GB/s)
  public static let gigabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.gigabytes,
    per: UnitDuration.seconds
  )

  /// Megabytes per second (MB/s)
  public static let megabytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.megabytes,
    per: UnitDuration.seconds
  )

  /// Kilobytes per second (KB/s)
  public static let kilobytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.kilobytes,
    per: UnitDuration.seconds
  )

  /// Yottabits per second (Ybps)
  public static let yottabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.yottabits,
    per: UnitDuration.seconds
  )

  /// Zettabits per second (Zbps)
  public static let zettabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.zettabits,
    per: UnitDuration.seconds
  )

  /// Exabits per second (Ebps)
  public static let exabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.exabits,
    per: UnitDuration.seconds
  )

  /// Petabits per second (Pbps)
  public static let petabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.petabits,
    per: UnitDuration.seconds
  )

  /// Terabits per seond (Tbps)
  public static let terabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.terabits,
    per: UnitDuration.seconds
  )

  /// Gigabits per second (Gbps)
  public static let gigabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.gigabits,
    per: UnitDuration.seconds
  )

  /// Megabits per second (Mbps)
  public static let megabitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.megabits,
    per: UnitDuration.seconds
  )

  /// Kilobits per second (Kbps)
  public static let kilobitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.kilobits,
    per: UnitDuration.seconds
  )

  /// Yobibytes per second (YiB/s)
  public static let yobibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.yobibytes,
    per: UnitDuration.seconds
  )

  /// Zebibytes per second (ZiB/s)
  public static let zebibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.zebibytes,
    per: UnitDuration.seconds
  )

  /// Exbibytes per second (EiB/s)
  public static let exbibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.exbibytes,
    per: UnitDuration.seconds
  )

  /// Pebibytes per second (PiB/s)
  public static let pebibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.pebibytes,
    per: UnitDuration.seconds
  )

  /// Tebibytes per second (TiB/s)
  public static let tebibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.tebibytes,
    per: UnitDuration.seconds
  )

  /// Gibibytes per second (GiB/s)
  public static let gibibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.gibibytes,
    per: UnitDuration.seconds
  )

  /// Mebibytes per second (MiB/s)
  public static let mebibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.mebibytes,
    per: UnitDuration.seconds
  )

  /// Kibibytes per second (KiB/s)
  public static let kibibytesPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.kibibytes,
    per: UnitDuration.seconds
  )

  /// Yobibits per second (Ybit/s)
  public static let yobibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.yobibits,
    per: UnitDuration.seconds
  )

  /// Zebibits per second (Zbit/s)
  public static let zebibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.zebibits,
    per: UnitDuration.seconds
  )

  /// Exbibits per second (Ebit/s)
  public static let exbibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.exbibits,
    per: UnitDuration.seconds
  )

  /// Pebibits per second (Pbit/s)
  public static let pebibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.pebibits,
    per: UnitDuration.seconds
  )

  /// Tebibits per second (Tbit/s)
  public static let tebibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.tebibits,
    per: UnitDuration.seconds
  )

  /// Gibibits per second (Gbit/s)
  public static let gibibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.gibibits,
    per: UnitDuration.seconds
  )

  /// Mebibits per second (Mbit/s)
  public static let mebibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.mebibits,
    per: UnitDuration.seconds
  )

  /// Kibibits per second (Kbit/s)
  public static let kibibitsPerSecond: UnitInformationTransferRate = unit(
    UnitInformationStorage.kibibits,
    per: UnitDuration.seconds
  )

  override public class func baseUnit() -> Self { bitsPerSecond as! Self }
}
