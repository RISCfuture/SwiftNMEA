import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.31 DTM")
struct DTMTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .datumReference,
      fields: [
        "999", "F",
        "13.2", "N",
        "22.8", "W",
        "-12.5",
        "W84", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .datumReference(
        localDatum,
        latitudeOffset,
        longitudeOffset,
        altitudeOffset,
        referenceDatum
      ) = payload
    else {
      Issue.record("expected .datumReference, got \(payload)")
      return
    }

    #expect(localDatum == .userDefined(subdivision: "F"))
    #expect(latitudeOffset == .init(value: 13.2, unit: .arcMinutes))
    #expect(longitudeOffset == .init(value: -22.8, unit: .arcMinutes))
    #expect(altitudeOffset == .init(value: -12.5, unit: .meters))
    #expect(referenceDatum == .WGS84)
  }

  @Test("parses a BDCS reference datum (C00)")
  func parsesABDCSReferenceDatumC00() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .datumReference,
      fields: [
        "C00", nil,
        nil, nil,
        nil, nil,
        nil,
        "C00", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .datumReference(localDatum, _, _, _, referenceDatum) = payload else {
      Issue.record("expected .datumReference, got \(payload)")
      return
    }
    #expect(localDatum == .BDCS)
    #expect(referenceDatum == .BDCS)
  }

  @Test("parses a sentence with an unknown (null) local datum")
  func parsesASentenceWithAnUnknownNullLocalDatum() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .datumReference,
      fields: [
        nil, nil,
        nil, nil,
        nil, nil,
        nil,
        "W84", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .datumReference(localDatum, _, _, _, referenceDatum) = payload
    else {
      Issue.record("expected .datumReference, got \(payload)")
      return
    }

    #expect(localDatum == nil)
    #expect(referenceDatum == .WGS84)
  }

  @Test("throws when a user-defined datum omits an offset")
  func throwsWhenAUserDefinedDatumOmitsAnOffset() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .datumReference,
      fields: [
        "999", "F",
        "13.2", "N",
        nil, "W",
        "-12.5",
        "W84", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 4)
  }

  @Test("throws for an invalid latitude-offset hemisphere character")
  func throwsForAnInvalidLatitudeOffsetHemisphereCharacter() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GNSS,
      format: .datumReference,
      fields: [
        "999", "F",
        "13.2", "X",
        "22.8", "W",
        "-12.5",
        "W84", nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .badCharacterValue)
    #expect(error.fieldNumber == 3)
  }
}
