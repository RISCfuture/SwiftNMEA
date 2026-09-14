import Foundation

/// The UTC Gregorian calendar that NMEA date and time fields are expressed in.
private let UTC = Calendar(identifier: .gregorian)

/// `hhmmss.ss` — a time of day with hundredths of a second, as used by the
/// time fields of most sentences.
let hmsFractionFormat = Date.VerbatimFormatStyle(
  format: """
    \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))\(minute: .twoDigits)\(second: .twoDigits).\(secondFraction: .fractional(2))
    """,
  timeZone: .gmt,
  calendar: UTC
)

/// `ddmmyyyy` — a day, month, and four-digit year, as used by the date fields
/// of sentences such as `RMC` and `LRF`.
let dateFormat = Date.VerbatimFormatStyle(
  format: "\(day: .twoDigits)\(month: .twoDigits)\(year: .padded(4))",
  timeZone: .gmt,
  calendar: UTC
)

/// `dd` — a day of the month on its own, as used by `VSD`.
let dayFormat = Date.VerbatimFormatStyle(
  format: "\(day: .twoDigits)",
  timeZone: .gmt,
  calendar: UTC
)

/// `mm` — a month on its own, as used by `VSD`.
let monthFormat = Date.VerbatimFormatStyle(
  format: "\(month: .twoDigits)",
  timeZone: .gmt,
  calendar: UTC
)
