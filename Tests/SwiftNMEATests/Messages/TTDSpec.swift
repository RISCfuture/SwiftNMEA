import Foundation
import Testing

@testable import SwiftNMEA

/// A protocol-zero (90-bit) tracked-target structure matching the canonical
/// values asserted in the BitCoder and TTD specs (target number 123, etc.).
private func protocolZeroTarget(into writer: inout BitWriter) {
  writer.write(0, bits: 2)  // protocol version
  writer.write(123, bits: 10)  // target number
  writer.write(1234, bits: 12)  // bearing
  writer.write(155, bits: 12)  // speed
  writer.write(1357, bits: 12)  // course
  writer.write(4095, bits: 12)  // heading (radar target)
  writer.write(0b100, bits: 3)  // status
  writer.write(0, bits: 1)  // test target
  writer.write(16300, bits: 14)  // distance
  writer.write(1, bits: 1)  // speed/course relative
  writer.write(0, bits: 1)  // stabilisation mode
  writer.write(0, bits: 2)  // reserved
  writer.write(128, bits: 8)  // correlation number
}

/// A protocol-one (42-bit) CPA/TCPA tracked-target structure.
private func protocolOneTarget(
  into writer: inout BitWriter,
  number: UInt16,
  CPA: UInt16,
  TCPA: Int16
) {
  writer.write(1, bits: 2)  // protocol version
  writer.write(number, bits: 10)  // target number
  writer.write(CPA, bits: 14)  // CPA distance
  writer.write(TCPA, bits: 14)  // TCPA (two's complement)
  writer.write(0, bits: 2)  // reserved
}

@Suite("8.3.107 TTD")
struct TTDTests {
  // MARK: - .parse

  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let target = Data([
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
    ])
    let (chunks, fillBits) = sixBit.encode(target, chunkSize: 60)

    let sentences = encapsulatedSentences(
      format: .trackedTargets,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [],
      hex: true
    )
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case .trackedTargets(let targets) = payload else {
      Issue.record("expected .trackedTargets, got \(payload)")
      return
    }

    #expect(targets.count == 1)
    #expect(targets[0].protocolVersion == 0)
    #expect(targets[0].number == 123)
    #expect(targets[0].bearing!.angle == .init(value: 123.4, unit: .degrees))
    #expect(targets[0].bearing!.reference == .true)
    #expect(targets[0].speed == .init(value: 15.5, unit: .knots))
    #expect(abs(targets[0].course!.value - 135.7) < 0.1)
    #expect(targets[0].heading == nil)
    #expect(targets[0].isRadarTarget)
    #expect(targets[0].status == .activatedNoAlarm)
    #expect(!targets[0].isTestTarget)
    #expect(targets[0].distance == .init(value: 163, unit: .nauticalMiles))
    #expect(targets[0].speedCourseRelative)
    #expect(!targets[0].waterStabilized)
    #expect(targets[0].correlationNumber == 128)
  }

  @Test("parses a single-sentence message with a null sequential identifier")
  func parsesASingleSentenceMessageWithANullSequentialIdentifier() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let target = Data([
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
    ])
    let (chunks, fillBits) = sixBit.encode(target, chunkSize: 60)

    // §8.3.107 footnote 2: the sequential identifier shall be null for a
    // message that fits into one sentence
    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], fillBits]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case .trackedTargets(let targets) = payload else {
      Issue.record("expected .trackedTargets, got \(payload)")
      return
    }

    #expect(targets.count == 1)
    #expect(targets[0].number == 123)
  }

  @Test("throws an error for an incorrect sentence number")
  func throwsAnErrorForAnIncorrectSentenceNumber() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let target = Data([
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00,
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
    ])
    let (chunks, fillBits) = sixBit.encode(target, chunkSize: 60)

    let sentences = [
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .trackedTargets,
        fields: ["02", "01", 1, chunks[0], fillBits]
      ),
      createSentence(
        delimiter: .encapsulated,
        talker: .commVHF,
        format: .trackedTargets,
        fields: ["02", "03", 1, chunks[1], fillBits]
      )
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 3)
    let error = try #require(messages[2] as? MessageError)
    #expect(error.type == .wrongSentenceNumber)
    #expect(error.fieldNumber == 1)
  }

  @Test("throws an error for an out-of-range fill-bits field")
  func throwsAnErrorForAnOutOfRangeFillBitsField() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    let target = Data([
      0x07, 0xB4, 0xD2, 0x09, 0xB5, 0x4D, 0xFF, 0xF8, 0xFE, 0xB2, 0x20, 0x00
    ])
    let (chunks, _) = sixBit.encode(target, chunkSize: 60)

    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], 99]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .badValue)
    #expect(error.fieldNumber == 4)
  }

  @Test("parses a protocol-one CPA/TCPA structure")
  func parsesAProtocolOneCPATCPAStructure()
    async throws
  {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    var writer = BitWriter(size: 42)
    // CPA 12,34 NM (1234 × 0,01); TCPA −56,78 min (−5678 × 0,01)
    protocolOneTarget(into: &writer, number: 42, CPA: 1234, TCPA: -5678)
    let (chunks, fillBits) = sixBit.encode(writer.data, chunkSize: 60)

    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], fillBits]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case .trackedTargets(let targets) = payload else {
      Issue.record("expected .trackedTargets, got \(payload)")
      return
    }

    #expect(targets.count == 1)
    #expect(targets[0].protocolVersion == 1)
    #expect(targets[0].number == 42)
    #expect(abs(targets[0].CPADistance!.converted(to: .nauticalMiles).value - 12.34) < 0.001)
    #expect(abs(targets[0].CPATime!.converted(to: .minutes).value - (-56.78)) < 0.001)
    // Protocol-zero–only fields are absent.
    #expect(targets[0].distance == nil)
    #expect(targets[0].bearing == nil)
  }

  @Test("parses a protocol-one structure with N/A sentinels as nil")
  func parsesAProtocolOneStructureWithNASentinelsAsNil() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    var writer = BitWriter(size: 42)
    // 16383 = N/A distance, −8192 = N/A time
    protocolOneTarget(into: &writer, number: 7, CPA: 16383, TCPA: -8192)
    let (chunks, fillBits) = sixBit.encode(writer.data, chunkSize: 60)

    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], fillBits]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let payload = (messages[1] as? Message)?.payload,
      case .trackedTargets(let targets) = payload
    else {
      Issue.record("expected .trackedTargets, got \(messages[1])")
      return
    }
    #expect(targets.count == 1)
    #expect(targets[0].CPADistance == nil)
    #expect(targets[0].CPATime == nil)
  }

  @Test("parses a sentence mixing protocol-zero and protocol-one structures")
  func parsesASentenceMixingProtocolZeroAndProtocolOneStructures() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    // Per footnote 3, protocol-zero structures precede protocol-one
    // structures within a sentence.
    var writer = BitWriter(size: 90 + 42)
    protocolZeroTarget(into: &writer)
    protocolOneTarget(into: &writer, number: 88, CPA: 500, TCPA: 100)
    let (chunks, fillBits) = sixBit.encode(writer.data, chunkSize: 60)

    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], fillBits]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let payload = (messages[1] as? Message)?.payload,
      case .trackedTargets(let targets) = payload
    else {
      Issue.record("expected .trackedTargets, got \(messages[1])")
      return
    }
    #expect(targets.count == 2)
    #expect(targets[0].protocolVersion == 0)
    #expect(targets[0].number == 123)
    #expect(targets[1].protocolVersion == 1)
    #expect(targets[1].number == 88)
    #expect(abs(targets[1].CPADistance!.converted(to: .nauticalMiles).value - 5) < 0.001)
  }

  @Test("throws for an unknown protocol version")
  func throwsForAnUnknownProtocolVersion()
    async throws
  {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    var writer = BitWriter(size: 42)
    writer.write(0b10, bits: 2)  // reserved protocol version 2
    writer.write(0, bits: 40)
    let (chunks, fillBits) = sixBit.encode(writer.data, chunkSize: 60)

    let sentence = createSentence(
      delimiter: .encapsulated,
      talker: .commVHF,
      format: .trackedTargets,
      fields: ["01", "01", nil, chunks[0], fillBits]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let error = try #require(messages[1] as? MessageError)
    #expect(error.type == .badSixBitEncoding)
    #expect(error.fieldNumber == 3)
  }

  // MARK: - .flush

  @Test("flushes incomplete sentences")
  func flushesIncompleteSentences() async throws {
    let parser = SwiftNMEA()
    let sixBit = SixBitCoder()

    // Ten contiguous protocol-zero structures (900 bits = 150 characters
    // = three 60/60/30-character chunks).
    var writer = BitWriter(size: 90 * 10)
    for _ in 0..<10 { protocolZeroTarget(into: &writer) }
    let (chunks, fillBits) = sixBit.encode(writer.data, chunkSize: 60)
    #expect(chunks.count == 3)

    let sentences = encapsulatedSentences(
      format: .trackedTargets,
      from: chunks,
      fillBits: fillBits,
      sequenceID: 0,
      otherFields: [],
      hex: true
    )
    let data = sentences[0...1].joined().data(using: .ascii)!

    let parsed = try await parser.parse(data: data)
    #expect(parsed.count == 2)

    let messages = try await parser.flush(includeIncomplete: true)
    #expect(messages.count == 1)

    let message = try #require(messages[0] as? Message)
    guard case .trackedTargets(let targets) = message.payload else {
      Issue.record("expected .trackedTargets, got \(message)")
      return
    }

    // Two 60-character sentences decode to 712 bits; the trailing
    // partial structure is dropped, leaving seven complete 90-bit
    // structures.
    #expect(targets.count == 7)
  }
}
