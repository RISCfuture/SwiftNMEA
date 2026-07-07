import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.122 VTG")
struct VTGTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .groundSpeedCourse,
      fields: [
        123.4, "T", 124.5, "M",
        12.3, "N", 23.4, "K",
        "A"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .groundSpeedCourse(
        courseTrue,
        courseMagnetic,
        speedKnots,
        speedKph,
        mode
      ) = payload
    else {
      Issue.record("expected .groundSpeedCourse, got \(payload)")
      return
    }

    #expect(courseTrue.angle == .init(value: 123.4, unit: .degrees))
    #expect(courseTrue.reference == .true)
    #expect(courseMagnetic.angle == .init(value: 124.5, unit: .degrees))
    #expect(courseMagnetic.reference == .magnetic)
    #expect(speedKnots == .init(value: 12.3, unit: .knots))
    #expect(speedKph == .init(value: 23.4, unit: .kilometersPerHour))
    #expect(mode == .autonomous)
  }
}
