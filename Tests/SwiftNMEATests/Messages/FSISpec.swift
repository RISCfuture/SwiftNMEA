import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.37 FSI")
struct FSITests {
  @Test("parses example (a) from the spec")
  func parsesExampleAFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,020230,026140,m,0,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF(frequency: .init(value: 2023, unit: .kilohertz)))
    #expect(receive == .MF_HF(frequency: .init(value: 2614, unit: .kilohertz)))
    #expect(mode == .J3E)
    #expect(powerLevel == 0)
    #expect(type == .command)
  }

  @Test("parses example (b) from the spec")
  func parsesExampleBFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,020230,026140,m,5,R")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF(frequency: .init(value: 2023, unit: .kilohertz)))
    #expect(receive == .MF_HF(frequency: .init(value: 2614, unit: .kilohertz)))
    #expect(mode == .J3E)
    #expect(powerLevel == 5)
    #expect(type == .reply)
  }

  @Test("parses example (c) from the spec")
  func parsesExampleCFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,,021820,o,,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == nil)
    #expect(receive == .MF_HF(frequency: .init(value: 2182, unit: .kilohertz)))
    #expect(mode == .H3E)
    #expect(powerLevel == nil)
    #expect(type == .command)
  }

  @Test("parses the example (d) from the spec")
  func parsesTheExampleDFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CDFSI,900016,,d,9,R")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .VHF(mode: .standard, channel: 16))
    #expect(receive == nil)
    #expect(mode == .F3E_G3E_simplex)
    #expect(powerLevel == 9)
    #expect(type == .reply)
  }

  @Test("parses example (e) from the spec")
  func parsesExampleEFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,300821,,m,9,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF_telephone(channel: 821))
    #expect(receive == nil)
    #expect(mode == .J3E)
    #expect(powerLevel == 9)
    #expect(type == .command)
  }

  @Test("parses example (f) from the spec")
  func parsesExampleFFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,404001,,w,5,R")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF_teletype(band: 4, channel: 1))
    #expect(receive == nil)
    #expect(mode == .F1B_J2B)
    #expect(powerLevel == 5)
    #expect(type == .reply)
  }

  @Test("parses example (g) from the spec")
  func parsesExampleGFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,416193,,s,0,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF_teletype(band: 16, channel: 193))
    #expect(receive == nil)
    #expect(mode == .F1B_J2B_ARQ_NBDP)
    #expect(powerLevel == 0)
    #expect(type == .command)
  }

  @Test("parses example (h) from the spec")
  func parsesExampleHFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CTFSI,041620,043020,|,9,R")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == .MF_HF(frequency: .init(value: 4162, unit: .kilohertz)))
    #expect(receive == .MF_HF(frequency: .init(value: 4302, unit: .kilohertz)))
    #expect(mode == .F1C_F2C_F3C)
    #expect(powerLevel == 9)
    #expect(type == .reply)
  }

  @Test("parses example (i) from the spec")
  func parsesExampleIFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CXFSI,,021875,t,,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let message = try #require(messages[1] as? Message)
    guard
      case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) =
        message.payload
    else {
      Issue.record("expected .frequencySetInfo, got \(message)")
      return
    }

    #expect(transmit == nil)
    #expect(receive == .MF_HF(frequency: .init(value: 2187.5, unit: .kilohertz)))
    #expect(mode == .F1B_J2B_receive)
    #expect(powerLevel == nil)
    #expect(type == .command)
  }
}
