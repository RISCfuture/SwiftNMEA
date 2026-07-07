import Testing

@testable import SwiftNMEA

@Suite("8.3.2 AAM")
struct AAMTests {
  @Test("parses the sentence from the spec")
  func parsesTheSentenceFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCAAM,V,A,.15,N,CHAT-N6*56\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .waypointArrivalAlarm(
        arrivalCircleEntered,
        perpendicularPassed,
        arrivalCircleRadius,
        waypoint
      ) = payload
    else {
      Issue.record("expected .waypointArrivalAlarm, got \(payload)")
      return
    }

    #expect(!arrivalCircleEntered)
    #expect(perpendicularPassed)
    #expect(arrivalCircleRadius == .init(value: 0.15, unit: .nauticalMiles))
    #expect(waypoint == "CHAT-N6")
  }
}
