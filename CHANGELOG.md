# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-03

### Added

- SwiftDSE `GeoAreaEnhancement` message (ITU-R M.821-1 DSC expansion)

### Changed

- Raised the minimum Swift tools version to 6.3

### Fixed

- ACS: corrected swapped year and day date fields (IEC 61162-1 §8.3.8)
- Talker identifiers that serialized to invalid codes: magnetic autopilot `AM` → `AP`, combined GNSS `GS` → `GN` (Table 4)
- Malformed six-bit (AIS) payloads now report `.badSixBitEncoding` instead of silently coercing invalid characters
- Malformed `^HH` escape sequences now report a decode error instead of silently dropping bytes
- TUT: parse total and sentence numbers as hexadecimal (`00`–`FF`) and decode ISO 8859 parts 1–16 (the lexicographic range previously dropped 2–9)
- Radar/TTD: corrected the distance "not available" sentinel to 16383
- Malformed input now throws `NMEAError` instead of trapping (RTE missing route id, TLB duplicate target, non-positive sentence total)
- SwiftDSE `PositionEnhancement` / `PositionSourceDatum`: corrected raw-value encoding and added field-length validation

## [1.0.0] - 2026-05-01

### Added

- Initial release of SwiftNMEA
- Strongly-typed NMEA sentence parser supporting IEC 61162-1 maritime navigation standards
- Domain-restricted data types
- Multi-sentence message aggregation
- Swift 6 concurrency support
