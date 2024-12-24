# Using SwiftNMEA

This document gives a basic overview of how to use SwiftNMEA to parse messages
from a data stream.

## Parsing messages

SwiftNMEA is written to work with discontinuous streams of data. To use
SwiftNMEA, create a ``SwiftNMEA/SwiftNMEA`` instance and call 
``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)`` any time new data is
received on your bus:

```swift
let parser = SwiftNMEA()
while data = bus.receive() {
  let elements = try await parser.parse(data: data)
  handleElements(elements)
}
```

``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)`` returns an array of
``Element`` objects. An ``Element`` can be one of five concrete instances:

- ``ParametricSentence``: A command or reply from a talker containing
uninterpreted data.
- ``Message``: One or more ``ParametricSentence``s whose data has been interpreted
- ``ProprietarySentence``: A manufacturer-specific sentence (cannot be interpreted
into a ``Message``)
- ``Query``: A sentence requesting information from a talker
- ``MessageError``: An error that occurred while trying to generate a ``Message``
from one or more ``Sentence``s

Essentially, ``Sentence``s (parametric, query, or proprietary) contain raw,
uninterpreted data that has been parsed from the stream. When possible, the
sentences are further interpreted into semantic data, in the form of ``Message``s.
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

Note that you could skip some of these `guard`s by initializing your
``SwiftNMEA/SwiftNMEA`` parser with some filters, if you didn't care about any
other data:

```swift
let parser = SwiftNMEA(typeFilter: [Message.self], talkerFilter: [.GPS], formatFilter: [.GNSSFix])
```

## Multi-sentence messages

Most ``ParametricSentence``s produce ``Message``s on a 1:1 basis: For example,
the `GNS` sentence automatically produces a 
``Message/Payload-swift.enum/GNSSFix(_:time:mode:numSatellites:HDOP:geoidalSeparation:DGPSAge:DGPSReferenceStationID:status:)``
message when it is received, and ``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)``
will return two ``Element``s: The ``ParametricSentence`` and the ``Message``.

Other ``Message``s, however, are constructed from multiple sentences. An example
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
sentences and current sentence number, respectively. As
``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)`` is called with this data,
it will generate separate ``ParametricSentence`` elements for each new
sentence as normal. However, it is not until after the final (seventh) sentence
is received that ``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)`` will
return the interpreted
``Message/Payload-swift.enum/NAVTEXMessage(_:id:frequency:code:time:totalCharacters:badCharacters:isValid:)``
message, which contains the full decoded message.

If data reception is interrupted prior to receiving the final (seventh)
sentence, the
``Message/Payload-swift.enum/NAVTEXMessage(_:id:frequency:code:time:totalCharacters:badCharacters:isValid:)``
message will never be generated. The user can opt to call
``SwiftNMEA/SwiftNMEA/flush(talker:format:includeIncomplete:)`` periodically to
generate ``Message``s from incomplete multi-sentence transmissions.

A few formats do not have a way of specifying the final sentence (e.g., `GEN`).
These sentences will never result in ``Message``s by calling
``SwiftNMEA/SwiftNMEA/parse(data:ignoreChecksums:)``, only
``SwiftNMEA/SwiftNMEA/flush(talker:format:includeIncomplete:)``.

