/// 2.1.2.2 - Source and datum of position
///
/// - SeeAlso: ``Message/positionSourceDatum(_:)``
public struct PositionSourceDatum: RawRepresentable, Sendable, Codable, Equatable {
  public typealias RawValue = String

  /// The type of navigation receiver the position data was derived from and
  /// the status of that fix
  public let source: PositionSource

  /// Datum for calculating position with the VTS area
  public let datum: PositionSource.Datum

  /// The current fix resolution (GDOP for LORAN-C, HDOP for GPS fixes). Any
  /// GDOP or HDOP exceeding 9.9 is represented by 9.9.
  public let fixResolution: Double

  public var rawValue: String {
    let resolutionStr = String(format: "%02.0f", fixResolution * 10)
    return "\(source.rawValue)\(resolutionStr)"
  }

  public init?(rawValue: String) {
    guard ("000000"..."999999").contains(rawValue) else { return nil }

    let sourceStr = rawValue.slice(from: 0, to: 1)
    let resolutionStr = rawValue.slice(from: 2, to: 3)
    let datumStr = rawValue.slice(from: 4, to: 5)
    guard let source = PositionSource(rawValue: String(sourceStr)),
      let resolutionTens = Int(resolutionStr),
      let datum = PositionSource.Datum(rawValue: String(datumStr))
    else { return nil }

    self.source = source
    self.fixResolution = Double(resolutionTens) / 10
    self.datum = datum
  }
}

/// The type of positioning device used for VTS positioning, as described in
/// Rec. ITU-R M.821-1, table 4.
///
/// - SeeAlso: ``PositionSourceDatum``
public enum PositionSource: String, Sendable, Codable, Equatable {

  /// Current position data invalid
  case invalid = "00"

  /// Position data from differential GPS
  case differentialGPS = "01"

  /// Position data from uncorrected GPS
  case GPS = "02"

  /// Position data from differential LORAN-C
  case differentialLORAN = "03"

  /// Position data from uncorrected LORAN-C
  case LORAN = "04"

  /// Position data from GLONASS (ГЛОНАСС)
  case GLONASS = "05"

  /// Position data from radar fix
  case radar = "06"

  /// Position data from Decca
  case decca = "07"

  /// Position data from other source
  case other = "08"

  /**
   Datum for calculating position with the VTS area, as described in
   Rec. ITU-R M.821-1, table 5.
  
   - SeeAlso: ``PositionSourceDatum``
   */
  public enum Datum: String, Sendable, Codable, Equatable {

    /// WGS-84
    case WGS84 = "00"

    /// WGS-72
    case WGS72 = "01"

    /// Other datum
    case other = "02"
  }
}
