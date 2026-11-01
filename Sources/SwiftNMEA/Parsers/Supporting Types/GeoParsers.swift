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

final class LatitudeParser {
  private static let rx = LockedRegex<(Substring, Int, Double)> {
    Regex {
      Anchor.startOfSubject
      Capture {
        Repeat(.digit, count: 2)
      } transform: {
        Int($0)!
      }
      Capture {
        Repeat(.digit, count: 2)
        "."
        OneOrMore(.digit)
      } transform: {
        Double($0)!
      }
      Anchor.endOfSubject
    }
  }

  func parse(_ value: String, hemisphere: LatitudeHemisphere) -> Measurement<UnitAngle>? {
    guard let match = Self.rx.wholeMatch(in: value) else {
      return nil
    }
    let (_, degrees, minutes) = match.output
    var magnitude = Double(degrees) + minutes / 60.0
    if hemisphere == .south { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}

final class LongitudeParser {
  private static let rx = LockedRegex<(Substring, Int, Double)> {
    Regex {
      Anchor.startOfSubject
      Capture {
        Repeat(.digit, count: 3)
      } transform: {
        Int($0)!
      }
      Capture {
        Repeat(.digit, count: 2)
        "."
        OneOrMore(.digit)
      } transform: {
        Double($0)!
      }
      Anchor.endOfSubject
    }
  }

  func parse(_ value: String, hemisphere: LongitudeHemisphere) -> Measurement<UnitAngle>? {
    guard let match = Self.rx.wholeMatch(in: value) else {
      return nil
    }
    let (_, degrees, minutes) = match.output
    var magnitude = Double(degrees) + minutes / 60.0
    if hemisphere == .west { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}
