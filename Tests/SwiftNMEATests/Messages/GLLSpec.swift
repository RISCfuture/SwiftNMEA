import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.43 GLL")
struct GLLTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCGLL,4728.31,N,12254.25,W,091342,A,A*4C\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard case let .geoPosition(position, time, isValid, mode) = payload else {
      Issue.record("expected .geoPosition, got \(payload)")
      return
    }

    #expect(abs(position.latitude.value - 47.4718333333) < 0.000001)
    #expect(abs(position.longitude.value - -122.9041666667) < 0.000001)
    #expect(isValid)
    #expect(mode == .autonomous)

    let components = Calendar.current.dateComponents(in: .gmt, from: time)
    #expect(components.hour == 9)
    #expect(components.minute == 13)
    #expect(components.second == 42)
  }
}
