import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.117 VER")
struct VERTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {

    // MARK: Setup

    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 1,
          "GPS", "VENDORID", "UNIQUEID",
          "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 2,
          nil, nil, "UNIQUEID",
          "MSR2", nil, "SOFTV2", "HARDV2",
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          1, 1,
          "GPS", "VENDORID2", "UNIQUEID2",
          "MSR3", "MODELCODE2", "SOFTV3", "HARDV3",
          2
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 5)

    // MARK: Message 0

    guard let payload = (messages[2] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[2])")
      return
    }
    guard
      case let .version(
        type,
        vendorID,
        uniqueID,
        serialNumber,
        modelCode,
        softwareRevision,
        hardwareRevision
      ) = payload
    else {
      Issue.record("expected .route, got \(payload)")
      return
    }
    #expect(type == "GPS")
    #expect(vendorID == "VENDORID")
    #expect(uniqueID == "UNIQUEID")
    #expect(serialNumber == "MSR1 MSR2")
    #expect(modelCode == "MODELCODE1")
    #expect(softwareRevision == "SOFTV1 SOFTV2")
    #expect(hardwareRevision == "HARDV1 HARDV2")

    // MARK: Message 1

    guard let payload = (messages[4] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[4])")
      return
    }
    guard
      case let .version(
        type,
        vendorID,
        uniqueID,
        serialNumber,
        modelCode,
        softwareRevision,
        hardwareRevision
      ) = payload
    else {
      Issue.record("expected .version, got \(payload)")
      return
    }
    #expect(type == "GPS")
    #expect(vendorID == "VENDORID2")
    #expect(uniqueID == "UNIQUEID2")
    #expect(serialNumber == "MSR3")
    #expect(modelCode == "MODELCODE2")
    #expect(softwareRevision == "SOFTV3")
    #expect(hardwareRevision == "HARDV3")
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 1,
          "GPS", "VENDORID", "UNIQUEID",
          "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 3,
          nil, nil, "UNIQUEID",
          "MSR2", nil, "SOFTV2", "HARDV2",
          1
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  @Test("throws an error for a missing field")
  func parseThrowsAnErrorForAMissingField()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 1,
          nil, "VENDORID", "UNIQUEID",
          "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          2, 2,
          nil, nil, "UNIQUEID",
          "MSR2", nil, "SOFTV2", "HARDV2",
          1
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    guard let error = messages[2] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[2])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 2)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .version,
      fields: [
        2, 1,
        "GPS", "VENDORID", "UNIQUEID",
        "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
        1
      ]
    )
    let data = sentence.data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 1)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    guard let message = messages[0] as? Message else {
      Issue.record("expected Message, got \(messages[0])")
      return
    }
    guard
      case let .version(
        type,
        vendorID,
        uniqueID,
        serialNumber,
        modelCode,
        softwareRevision,
        hardwareRevision
      ) = message.payload
    else {
      Issue.record("expected .version, got \(message)")
      return
    }

    #expect(type == "GPS")
    #expect(vendorID == "VENDORID")
    #expect(uniqueID == "UNIQUEID")
    #expect(serialNumber == "MSR1 ")
    #expect(modelCode == "MODELCODE1")
    #expect(softwareRevision == "SOFTV1 ")
    #expect(hardwareRevision == "HARDV1 ")
  }

  @Test("throws an error for a missing field")
  func flushThrowsAnErrorForAMissingField()
    async throws
  {
    let parser = SwiftNMEA()
    let sentences = [
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          3, 1,
          nil, "VENDORID", "UNIQUEID",
          "MSR1 ", "MODELCODE1", "SOFTV1 ", "HARDV1 ",
          1
        ]
      ),
      createSentence(
        delimiter: .parametric,
        talker: .GPS,
        format: .version,
        fields: [
          3, 2,
          nil, nil, "UNIQUEID",
          "MSR2", nil, "SOFTV2", "HARDV2",
          1
        ]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 2)

    let flushed = try await parser.flush(includeIncomplete: true)
    #expect(flushed.count == 1)

    guard let error = flushed[0] as? MessageError else {
      Issue.record("expected MessageError, got \(flushed[0])")
      return
    }
    #expect(error.type == .missingRequiredValue)
    #expect(error.fieldNumber == 2)
  }
}
