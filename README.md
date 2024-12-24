# SwiftNMEA: A NMEA sentence parser for Swift

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

## Usage

SwiftNMEA is written to work with discontinuous streams of data. To use
SwiftNMEA, create a `SwiftNMEA` instance and call `parse` any time new data is
received on your bus:

```swift
let parser = SwiftNMEA()
while data = bus.receive() {
  let elements = try await parser.parse(data: data)
  handleElements(elements)
}
```

`parse` returns an array of `Element` objects. An `Element` can be one of five
concrete instances:

- `ParametricSentence`: A command or reply from a talker containing
  uninterpreted data.
- `Message`: One or more `ParametricSentence`s whose data has been interpreted
- `ProprietarySentence`: A manufacturer-specific sentence (cannot be interpreted
  into a `Message`)
- `Query`: A sentence requesting information from a talker
- `MessageError`: An error that occurred while trying to generate a `Message`
  from one or more `Sentence`s

Essentially, `Sentence`s (parametric, query, or proprietary) contain raw,
uninterpreted data that has been parsed from the stream. When possible, the
sentences are further interpreted into semantic data, in the form of `Message`s.
Sometimes this data is split across multiple sentences.

As an example, let's build a `handleElements` method that receives GPS position
information from a GPS talker, via the `GNS` sentence:

```swift
func handleElements(_ elements: [Element]) {
  for element in elements {
    guard let element = element as? Message else { continue }
    guard element.talker == .GPS else { continue }
    guard case let .GNSSFix(position, time, _, _, _, _, _, _, status) = element.payload else { continue }
    guard status == .safe else { continue }

    updatePosition(position.latitude.value, position.longitude.value, at: time)
  }
}
```

(This assumes a fictional `updatePosition` method.)

Note that you could skip some of these `guard`s by initializing your `SwiftNMEA`
parser with some filters, if you didn't care about any other data:

```swift
let parser = SwiftNMEA(typeFilter: [Message.self], talkerFilter: [.GPS], formatFilter: [.GNSSFix])
```

### Multi-sentence messages

Most `ParametricSentence`s produce `Message`s on a 1:1 basis: For example, the
`GNS` sentence automatically produces a `GNSSFix` message when it is received,
and `parse` will return two `Element`s: The `ParametricSentence` and the
`Message`.

Other `Message`s, however, are constructed from multiple sentences. An example
is the `NRX` sentence, which contains a received NAVTEX message. This NAVTEX
message may be longer than a single sentence, and thus is split into multiple
sentences like so:

```
$CRNRX,007,001,00,IE69,1,135600,27,06,2001,241,3,A,==========================*09
$CRNRX,007,002,00,,,,,,,,,,========^0D^0AISSUED ON SATURDAY 06 JANUARY 2001.*29
$CRNRX,007,003,00,,,,,,,,,,^0D^0AINSHORE WATERS FORECAST TO 12 MILES^0D^0AOFF*0D
$CRNRX,007,004,00,,,,,,,,,,SHORE FROM 1700 UT^2A TO 0500 UTC.^0D^0A^0D^0ANORT*70
$CRNRX,007,005,00,,,,,,,,,,H FORELAND TO SE^2A^2AEY BILL.^0D^0A12 HOURS FOREC*16
$CRNRX,007,006,00,,,,,,,,,,AST:^0D^0A^0ASHOWERY WINDS^2C STRONGEST IN NORTH. *3C
$CRNRX,007,007,00,,,,,,,,,, ^0D ^0A^0D ^0A*79
```

The first and second fields after the address field are the total number of
sentences and current sentence number, respectively. As `parse` is called with
this data, it will generate separate `ParametricSentence` elements for each new
sentence as normal. However, it is not until after the final (seventh) sentence
is received that `parse` will return the interpreted `NAVTEX` message, which
contains the full decoded message.

If data reception is interrupted prior to receiving the final (seventh)
sentence, the `NAVTEX` message will never be generated. The user can opt to call
`flush` periodically to generate `Message`s from incomplete multi-sentence
transmissions.

A few formats do not have a way of specifying the final sentence (e.g., `GEN`).
These sentences will never result in `Message`s by calling `parse`, only
`flush`.

### Important caveat on nullability

Sadly, IEC 61162-1 does not do a good job of specifying nullability
consistently. (Sometimes they explicitly say a field should never be null;
sometimes they explicitly say a field may be null; and sometimes they do not
specify either way). Because of this, I decided to take the most restrictive
approach and mark all fields as required unless a spec or example specifically
indicates that they are permitted to be null.

As before, you may need to modify this library as you discover nullable fields
that deviate from these assumptions.

## Associated Libraries

This Swift Package Manager project contains a few additional products aside from
the SwiftNMEA library that you can use in your projects:

- **SwiftDSE**: This package contains types for parsing and generating DSE
  (digital selective calling) messages. It was written to work with the `DSC`
  and `DSE` sentence formats but extracted into its own library for independent
  use.
- **NMEACommon**: Contains utility types and functions shared by SwiftNMEA and
  SwiftDSE.
- **NMEAUnits**: Extends Apple's `Measurement` and `Dimension` types with
  additional units of measure used by the NMEA spec (e.g., force, flow rate).

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
