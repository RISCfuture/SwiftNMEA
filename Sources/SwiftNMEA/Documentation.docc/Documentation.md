# ``SwiftNMEA``

SwiftNMEA is a Swift-native, strongly-typed NMEA sentence parser and
interpreter. It's designed to work with streams of data, and emit parsed and
interpreted data extracted from NMEA sentences.

SwiftNMEA primarily implements IEC 61162-1, edition 4.0 (2010-11). Some
additional support is added for differences in real-world NMEA applications,
such as GPS receiver ICs, but it is expected that users of this library will
need to extend it at least slightly to conform to real-world deviations from the
spec.

## Requirements

SwiftNMEA is a Swift Package Manager project supporting both Swift 5.0 and 6.0
language modes. Additional platform requirements are specified in the
`Package.swift` file.

## Installation

To use SwiftNMEA with a Swift Package Manager project, add the GitHub repository
URL to your `dependencies` section in your `Package.swift` file:

```swift
let package = Package(
  // ...
  dependencies: [
    .package(url: "https://github.com/RISCfuture/SwiftNMEA.git", from: "1.0.0"),
    // ...
  ]
  // ...
)
```

To use it in a Xcode project, add the GitHub URL to the **Package Dependencies**
section in your project configuration.

## Philosophy

Like my other projects [SwiftNASR](https://github.com/RISCfuture/SwiftNASR) and
 [SwiftMETAR](https://github.com/RISCfuture/SwiftMETAR), SwiftNMEA's general
philosophy is **domain-restricted data** when possible. Instead of open-ended
types like Strings and Ints, SwiftNMEA uses constrained types like enums and
structs to help ensure data integrity. This has the negative side effect of
increasing the likelihood of parsing errors when working with talkers that send
partially-invalid data, or that do not adhere exactly to the NMEA spec as
written in IEC 61162-1.

To this end, some affordance has been made for NMEA "in the wild" as the
maintainers require; it is expected that if you are working with this library,
you may need to modify or extend it as well.

### Important caveat on nullability

Sadly, IEC 61162-1 does not do a good job of specifying nullability
consistently. (Sometimes they explicitly say a field should never be null;
sometimes they explicitly say a field may be null; and sometimes they do not
specify either way). Because of this, I decided to take the most restrictive
approach and mark all fields as required unless a spec or example specifically
indicates that they are permitted to be null.

As before, you may need to modify this library as you discover nullable fields
that deviate from these assumptions.

## Sources Used

SwiftNMEA has been written to conform to the following specs as published:

- IEC 61162-1, edition 4.0, 2010-11: "Maritime navigation and radiocommunication
  equipment and systems – Digital interfaces – Part 1: Single talker and multiple
  listeners"
- Rec. ITU-R M.493-16 (12/2023): "Digital selective-calling system for use in the
  maritime mobile service"
- Rec. ITU-R M.821-1 (1992–1997): "Optional expansion of the digital selective-calling
  system for use in the maritime mobile service"
- Rec. ITU-R M.1371-5 (02/2014): "Technical characteristics for an automatic
  identification system using time division multiple access in the VHF maritime
  mobile frequency band"


## Topics

### Parsing messages

- <doc:Usage>
- ``SwiftNMEA/SwiftNMEA``
- ``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)``
- ``SwiftNMEA/SwiftNMEA/flush(talker:format:includeIncomplete:)``

### Parsed types

- ``Element``
- ``Sentence``
- ``ParametricSentence``
- ``Query``
- ``ProprietarySentence``
- ``Message``
- ``MessageError``

### Sentence structure

- ``Delimiter``
- ``Format``
- ``Talker``

### Common types

- ``Bearing``
- ``BearingRange``
- ``Coordinate``
- ``Dimensions``
- ``RelativeWindReference``
- ``SentenceType``
- ``SpeedVector``

### Supporting types

- ``AISLongRange``
- ``AIS``
- ``AlarmCondition``
- ``AlarmAcknowledgementState``
- ``Comm``
- ``CourseSpeedReference``
- ``Datum``
- ``DimmingPreset``
- ``DisplayRotation``
- ``Doors``
- ``DSC``
- ``DSE``
- ``EngineTelegraph``
- ``Fire``
- ``GNSS``
- ``Heading``
- ``HeadingSensor``
- ``MSK``
- ``NAKReason``
- ``Navaid``
- ``Navigation``
- ``NAVTEX``
- ``Propulsion``
- ``Radar``
- ``Steering``
- ``Transducer``
- ``WaterSensor``

### Custom parsing

- ``Fields``

### Errors

- ``ErrorType``
- ``NMEAError``
