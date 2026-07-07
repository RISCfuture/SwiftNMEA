import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.108 TTM")
struct TTMTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let time = Date(timeIntervalSinceNow: -10)
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .radar,
      format: .trackedTarget,
      fields: [
        12,
        12.3, 234.5, "T", 15.5, 110.1, "R",
        45.6, 10.7, "K",
        "TGT1", "T", "R", hmsFractionFormatter.string(from: time), "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .trackedTarget(
        number,
        distance,
        bearing,
        speed,
        course,
        CPADistance,
        CPATime,
        name,
        status,
        isReference,
        actualTime,
        acquisition
      ) =
        payload
    else {
      Issue.record("expected .trackedTarget, got \(payload)")
      return
    }

    #expect(number == 12)
    #expect(distance == .init(value: 12.3, unit: .kilometers))
    #expect(bearing.angle == .init(value: 234.5, unit: .degrees))
    #expect(bearing.reference == .true)
    #expect(speed == .init(value: 15.5, unit: .kilometersPerHour))
    #expect(course.angle == .init(value: 110.1, unit: .degrees))
    #expect(course.reference == .relative)
    #expect(CPADistance == .init(value: 45.6, unit: .kilometers))
    #expect(CPATime == .init(value: 10.7, unit: .minutes))
    #expect(name == "TGT1")
    #expect(status == .tracking)
    #expect(isReference)
    #expect(abs(actualTime.timeIntervalSince(time)) < 0.01)
    #expect(acquisition == .automatic)
  }
}
