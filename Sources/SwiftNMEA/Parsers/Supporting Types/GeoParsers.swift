import Foundation
@preconcurrency import RegexBuilder

enum LatitudeHemisphere: String {
  case north = "N"
  case south = "S"
}

enum LongitudeHemisphere: String {
  case east = "E"
  case west = "W"
}

final class LatitudeParser {
  private let degrees = Reference<Int>()
  private let minutes = Reference<Double>()
  private lazy var rx = Regex {
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

  func parse(_ value: String, hemisphere: LatitudeHemisphere) throws -> Measurement<UnitAngle>? {
    guard let match = try rx.firstMatch(in: value) else {
      return nil
    }
    var magnitude = Double(match[degrees]) + match[minutes] / 60.0
    if hemisphere == .south { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}

final class LongitudeParser {
  private let degrees = Reference<Int>()
  private let minutes = Reference<Double>()
  private lazy var rx = Regex {
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

  func parse(_ value: String, hemisphere: LongitudeHemisphere) throws -> Measurement<UnitAngle>? {
    guard let match = try rx.firstMatch(in: value) else {
      return nil
    }
    var magnitude = Double(match[degrees]) + match[minutes] / 60.0
    if hemisphere == .west { magnitude *= -1 }
    return .init(value: magnitude, unit: .degrees)
  }
}
