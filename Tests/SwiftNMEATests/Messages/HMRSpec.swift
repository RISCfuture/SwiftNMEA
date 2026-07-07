import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.53 HMR")
struct HMRTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedInstrumentation,
      format: .headingMonitorReceive,
      fields: [
        "HDG1", "HDG2",
        5.0, 6.0, "V",
        96.2, "A", "M", 6.5, "E",
        90.2, "V", "T", nil, nil,
        3.5, "W"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .headingMonitorReceive(
        sensor1,
        sensor2,
        setDifference,
        difference,
        differenceOK,
        variation
      ) = payload
    else {
      Issue.record("expected .headingMonitorReceive, got \(payload)")
      return
    }

    #expect(sensor1.id == "HDG1")
    #expect(sensor1.heading.angle == .init(value: 96.2, unit: .degrees))
    #expect(sensor1.heading.reference == .magnetic)
    #expect(sensor1.deviation == .init(value: 6.5, unit: .degrees))
    #expect(sensor1.isValid)

    #expect(sensor2.id == "HDG2")
    #expect(sensor2.heading.angle == .init(value: 90.2, unit: .degrees))
    #expect(sensor2.heading.reference == .true)
    #expect(sensor2.deviation == nil)
    #expect(!sensor2.isValid)

    #expect(setDifference == .init(value: 5.0, unit: .degrees))
    #expect(difference == .init(value: 6.0, unit: .degrees))
    #expect(!differenceOK)
    #expect(variation == .init(value: -3.5, unit: .degrees))
  }
}
