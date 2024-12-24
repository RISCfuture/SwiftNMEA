import Foundation
import NMEAUnits
@preconcurrency import RegexBuilder

final class TimeParser {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private let hours = Reference<Int>()
    private let minutes = Reference<Int>()
    private let seconds = Reference<Double>()

    private lazy var decimalRx = Regex {
        Anchor.startOfSubject
        Capture(as: hours) {
            Repeat(.digit, count: 2)
        } transform: { Int($0)! }
        Capture(as: minutes) {
            Repeat(.digit, count: 2)
        } transform: { Int($0)! }
        Capture(as: seconds) {
            Repeat(.digit, count: 2)
            "."
            OneOrMore(.digit)
        } transform: { Double($0)! }
        Anchor.endOfSubject
    }

    private lazy var wholeRx = Regex {
        Anchor.startOfSubject
        Capture(as: hours) {
            Repeat(.digit, count: 2)
        } transform: { Int($0)! }
        Capture(as: minutes) {
            Repeat(.digit, count: 2)
        } transform: { Int($0)! }
        Capture(as: seconds) {
            Repeat(.digit, count: 2)
        } transform: { Double($0)! }
        Anchor.endOfSubject
    }

    func hmsDecimalComponents(_ value: String, timeZone: TimeZone = .gmt) throws -> DateComponents? {
        guard let match = try decimalRx.firstMatch(in: value) else { return nil }

        let hour = match[hours],
            minute = match[minutes],
            second = match[seconds]
        let (intSecond, fracSecond) = modf(second)
        let nanosecond = Int(fracSecond * 1_000_000_000)

        return .init(calendar: calendar, timeZone: timeZone, hour: hour, minute: minute, second: Int(intSecond), nanosecond: nanosecond)
    }

    func hmsComponents(_ value: String, timeZone: TimeZone = .gmt) throws -> DateComponents? {
        guard let match = try wholeRx.firstMatch(in: value) else { return nil }

        let hour = match[hours],
            minute = match[minutes],
            second = match[seconds]

        return .init(calendar: calendar, timeZone: timeZone, hour: hour, minute: minute, second: Int(second))
    }

    func parseHmsDecimal(_ value: String, searchDirection: Calendar.SearchDirection, referenceDate: Date = .now, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let components = try hmsDecimalComponents(value, timeZone: timeZone) else { return nil }

        // Find the next future/past date with the given hour, minute, and second
        return calendar.nextDate(after: referenceDate,
                                 matching: components,
                                 matchingPolicy: .strict,
                                 repeatedTimePolicy: .first,
                                 direction: searchDirection)
    }

    func parseHmsDecimalDuration(_ value: String) throws -> Duration? {
        guard let match = try decimalRx.firstMatch(in: value) else { return nil }

        let hour = match[hours],
            minute = match[minutes],
            second = match[seconds]
        let (intSecond, fracSecond) = modf(second)
        let nanosecond = Int(fracSecond * 1_000_000_000)

        return .hours(hour) + .minutes(minute) + .seconds(intSecond) + .nanoseconds(nanosecond)
    }

    func parseHms(_ value: String, searchDirection: Calendar.SearchDirection, referenceDate: Date = .now, timeZone: TimeZone = .gmt) throws -> Date? {
        guard let components = try hmsComponents(value, timeZone: timeZone) else { return nil }

        // Find the next future/past date with the given hour, minute, and second
        return calendar.nextDate(after: referenceDate,
                                 matching: components,
                                 matchingPolicy: .strict,
                                 repeatedTimePolicy: .first,
                                 direction: searchDirection)
    }
}
