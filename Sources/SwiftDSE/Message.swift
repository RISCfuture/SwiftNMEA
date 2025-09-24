/// A Digital Selective-Calling (DSC) System expansion sequence as defined in
/// Rec. ITU-R M.821-1.
///
/// The Recommendation provides in Annex 1 optional expansion sequences to calls in
/// the digital selective-calling (DSC) system described in Recommendations
/// ITU-R M.493 and ITU-R M.541. These expansion sequences enable DSC equipment to
/// transmit optional messages of more precise geographic coordinates, the
/// navigation equipment used to derive the position, the datum used for its
/// calculation and the resolution of the fix, ship's speed, course or alternative
/// ship identification.
public enum Message: Sendable, Codable, Equatable {

  /// 2.1.2.1 - Enhanced position resolution
  case enhancedPositionResolution(_ position: Content<PositionEnhancement>)

  /// 2.1.2.2 - Source and datum of position
  case positionSourceDatum(_ sourceDatum: Content<PositionSourceDatum>)

  /// 2.1.2.3 - Current speed of the vessel
  case speed(_ speed: Content<Speed>)

  /// 2.1.2.4 - Current course of the vessel
  case course(_ course: Content<Course>)

  /// 2.1.2.5 - Additional station identification
  case additionalID(_ ID: Content<Text>)

  /// 2.1.2.6 - Enhanced geographic area
  case enhnancedGeoArea(_ geoArea: Content<GeoAreaEnhancement>)

  /// 2.1.2.7 - Number of persons on board
  case personsOnboard(_ count: Content<Number>)
}
