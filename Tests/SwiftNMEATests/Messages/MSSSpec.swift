import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.66 MSS")
struct MSSTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$CRMSS,50,17,293.0,100,1*55\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .MSKReceiverSignalStatus(
        signalStrength,
        SNR,
        frequency,
        bitRate,
        channel
      ) = payload
    else {
      Issue.record("expected .MSKReceiverSignalStatus, got \(payload)")
      return
    }

    #expect(signalStrength == 50)
    #expect(SNR == 17)
    #expect(frequency == .init(value: 293.0, unit: .kilohertz))
    #expect(bitRate == .init(value: 100, unit: .bitsPerSecond))
    #expect(channel == 1)
  }
}
