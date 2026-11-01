import Foundation
import NMEAUnits
import RegexBuilder

final class TimeParser {

  private static let decimalRx = LockedRegex<(Substring, Int, Int, Double)> {
    Regex {
      Anchor.startOfSubject
      Capture {
        Repeat(.digit, count: 2)
      } transform: {
        Int($0)!
      }
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

  private static let wholeRx = LockedRegex<(Substring, Int, Int, Double)> {
    Regex {
      Anchor.startOfSubject
      Capture {
        Repeat(.digit, count: 2)
      } transform: {
        Int($0)!
      }
      Capture {
        Repeat(.digit, count: 2)
      } transform: {
        Int($0)!
      }
      Capture {
        Repeat(.digit, count: 2)
      } transform: {
        Double($0)!
      }
      Anchor.endOfSubject
    }
  }

  var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  func hmsDecimalComponents(_ value: String, timeZone: TimeZone = .gmt) -> DateComponents? {
    guard let match = Self.decimalRx.wholeMatch(in: value) else { return nil }

    let (_, hour, minute, second) = match.output
    let (intSecond, fracSecond) = modf(second)
    let nanosecond = Int(fracSecond * 1_000_000_000)

    return .init(
      calendar: calendar,
      timeZone: timeZone,
      hour: hour,
      minute: minute,
      second: Int(intSecond),
      nanosecond: nanosecond
    )
  }

  func hmsComponents(_ value: String, timeZone: TimeZone = .gmt) -> DateComponents? {
    guard let match = Self.wholeRx.wholeMatch(in: value) else { return nil }

    let (_, hour, minute, second) = match.output

    return .init(
      calendar: calendar,
      timeZone: timeZone,
      hour: hour,
      minute: minute,
      second: Int(second)
    )
  }

  func parseHmsDecimal(
    _ value: String,
    searchDirection: Calendar.SearchDirection,
    referenceDate: Date = .now,
    timeZone: TimeZone = .gmt
  ) -> Date? {
    guard let components = hmsDecimalComponents(value, timeZone: timeZone) else { return nil }

    // Find the next future/past date with the given hour, minute, and second
    return calendar.nextDate(
      after: referenceDate,
      matching: components,
      matchingPolicy: .strict,
      repeatedTimePolicy: .first,
      direction: searchDirection
    )
  }

  func parseHmsDecimalDuration(_ value: String) -> Duration? {
    guard let match = Self.decimalRx.wholeMatch(in: value) else { return nil }

    let (_, hour, minute, second) = match.output
    let (intSecond, fracSecond) = modf(second)
    let nanosecond = Int(fracSecond * 1_000_000_000)

    return .hours(hour) + .minutes(minute) + .seconds(intSecond) + .nanoseconds(nanosecond)
  }

  func parseHms(
    _ value: String,
    searchDirection: Calendar.SearchDirection,
    referenceDate: Date = .now,
    timeZone: TimeZone = .gmt
  ) -> Date? {
    guard let components = hmsComponents(value, timeZone: timeZone) else { return nil }

    // Find the next future/past date with the given hour, minute, and second
    return calendar.nextDate(
      after: referenceDate,
      matching: components,
      matchingPolicy: .strict,
      repeatedTimePolicy: .first,
      direction: searchDirection
    )
  }
}
