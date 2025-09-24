/// A preset dimmed level on an electronic device.
///
/// - SeeAlso: ``Message/Payload-swift.enum/displayDimmingControl(preset:brightness:colorPalette:status:)``
public enum DimmingPreset: Character, Sendable, Codable, Equatable {

  /// Day time setting
  case day = "D"

  /// Dusk setting
  case dusk = "K"

  /// Night time setting
  case night = "N"

  /// Backlighting off setting
  case off = "O"
}

/// Display rotation settings.
///
/// - SeeAlso: ``Message/Payload-swift.enum/radarSystemData(origin1:VRM1:EBL1:origin2:VRM2:EBL2:cursor:rangeScale:rotation:)``
public enum DisplayRotation: Character, Sendable, Codable, Equatable {

  /// Course-up, course-over-ground up, degrees true
  case courseUp = "C"

  /// Head-up, ship's heading (centre-line) 0° up
  case headingUp = "H"

  /// North-up, true north is 0° up
  case northUp = "N"
}
