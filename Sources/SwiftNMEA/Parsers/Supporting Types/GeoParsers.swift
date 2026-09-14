import Foundation
import RegexBuilder

enum LatitudeHemisphere: String {
  case north = "N"
  case south = "S"
}

enum LongitudeHemisphere: String {
  case east = "E"
  case west = "W"
}

enum LatitudeParser {
  private static let degrees = Reference<Int>()
  private static let minutes = Reference<Double>()

  private static let rx = LockedRegex(
    Regex {
      Anchor.startOfSubject
      Capture(as: degrees) {
        Repeat(.digit, count: 2)
      } transform: {
        Int($0)!
      }
      Capture(as: minutes) {
        Repeat(.digit, count: 2)
        "."
        OneOrMore(.digit)
      } transform: {
        Double($0)!
      }
      Anchor.endOfSubject
    }
  )

  static func parse(_ value: String, hemisphere: LatitudeHemisphere) throws
    -> Measurement<UnitAngle>?
  {
    guard let match = try rx.firstMatch(in: value) else {
      return nil
    }
    var magnitude = Double(match[degrees]) + match[minutes] / 60.0
    if hemisphere == .south { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}

enum LongitudeParser {
  private static let degrees = Reference<Int>()
  private static let minutes = Reference<Double>()

  private static let rx = LockedRegex(
    Regex {
      Anchor.startOfSubject
      Capture(as: degrees) {
        Repeat(.digit, count: 3)
      } transform: {
        Int($0)!
      }
      Capture(as: minutes) {
        Repeat(.digit, count: 2)
        "."
        OneOrMore(.digit)
      } transform: {
        Double($0)!
      }
      Anchor.endOfSubject
    }
  )

  static func parse(_ value: String, hemisphere: LongitudeHemisphere) throws
    -> Measurement<UnitAngle>?
  {
    guard let match = try rx.firstMatch(in: value) else {
      return nil
    }
    var magnitude = Double(match[degrees]) + match[minutes] / 60.0
    if hemisphere == .west { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}
