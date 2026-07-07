import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.65 MSK")
struct MSKTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = applyChecksum(to: "$CRMSK,293.0,M,100,A,,10,C")
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .MSKReceiverInterface(
        frequency,
        bitRate,
        statusInterval,
        channel,
        status
      ) = payload
    else {
      Issue.record("expected .MSKReceiverInterface, got \(payload)")
      return
    }

    #expect(frequency == .manual(.init(value: 293, unit: .kilohertz)))
    #expect(bitRate == .auto(.init(value: 100, unit: .bitsPerSecond)))
    #expect(statusInterval == nil)
    #expect(channel == 10)
    #expect(status == .command)
  }
}
