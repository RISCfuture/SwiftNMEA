/// A preset dimmed level on an electronic device.
///
/// - SeeAlso: ``Message/Payload-swift.enum/displayDimmingControl(preset:brightness:colorPalette:status:commandMode:)``
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

/// Indicates whether a ``DimmingPreset`` command applies to the current
/// operational state or to a stored preset setting.
///
/// - SeeAlso: ``Message/Payload-swift.enum/displayDimmingControl(preset:brightness:colorPalette:status:commandMode:)``
public enum DimmingCommandMode: Character, Sendable, Codable, Equatable {

  /// Sentence is relevant to current operational settings.
  case operational = "O"

  /// Sentence is relevant to stored “preset” settings.
  case preset = "P"
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
