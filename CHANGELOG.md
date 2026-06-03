# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-06-03

### Added

- IEC 61162-1 ed.6.0 §8.3 sentences: alert management (ACN, AGL, ALC, ALF, ARC); SafetyNET (SM1–SM4, SMB, SMV); EPM, EPV, GDC, HCR, HRM, VBC, SPW, NLS, SLM, SEL, RRT; MOB, NSR, RLM, TRL
- GNSS BeiDou, QZSS, and NavIC support (`GNSS.System`, `SatelliteID`, and the signal-ID tables; System IDs 4–6) and the GI/NavIC talker
- AIS (ITU-R M.1371-6): navigational status 11–14, AIS channels C/D (VDM/VDO long range), ABM/BBM message IDs 25/26/70/71, and TTD protocol-version-1 (CPA/TCPA) target structures
- GEN packed-binary data modeled as a sparse `[UInt16: Data]`, preserving interior no-update gaps

### Changed

- **Breaking:** migrated from IEC 61162-1 ed.4.0 (2010) / ITU-R M.1371-5 to ed.6.0 (2024) / M.1371-6
- **Breaking:** restructured `AISLongRange.ShipType` to M.1371-6 Table 51
- **Breaking:** GBS/GRS/GSV parse System and Signal IDs as hexadecimal; GSV derives its constellation from the talker; GNS decodes the six-character mode indicator
- Accept spec-permitted null fields instead of throwing (ABK, DPT, FIR, GRS, GSV, SSD, VER, NRX, MEB, TTD, DTM, RMC, OSD)
- ed.6.0 field-layout updates (AIR 12-field, DDC command mode, ROR 9-field, RSA 4-sensor) and enum/unit corrections (DC-propulsion and boiler-drum alarm codes; XDR dew point / fluid level and C/K, litres/h, percentage units; DTM BDCS; DSC first-telecommand codes)
- `DSC.FrequencyChannel` encode/decode now round-trips per M.493-16 Table A1-5
- The parser now surfaces `.unknownSentenceType` / `.sentenceTooLong` instead of silently dropping malformed lines
- Deprecated GGA, TTM, ACK, and ALR in favor of ACN/ALC/ALF

### Fixed

- Parser robustness: the GRS residual range, GEN entity-index arithmetic, and GBS/GDC/GRS/GSV hex-ID conversions now throw on malformed input instead of trapping
- GSV surfaces out-of-range satellite and signal IDs as field errors instead of leaking internal errors
- Multi-sentence reassembly requires strictly increasing sentence numbers and a consistent sentence total, preventing out-of-order payload corruption
- SafetyNET SM2 rejects out-of-range reception dates; SMB and SMV require a sentence number for multi-sentence messages
- EPV de-escapes its value field; TTD validates fill bits; DSC frequency encoding guards non-finite input; DTM reports the correct field for an invalid latitude-offset hemisphere

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
