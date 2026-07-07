import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.80 RMB")
struct RMBTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .GPS,
      format: .destinationMinimumData,
      fields: [
        "A",
        0.5, "L",
        "KSQL", "KOAK",
        "3630.00", "N", "12215.00", "W",
        15.5, 272.2, 13.5, "V",
        "D"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .destinationMinimumData(
        isValid,
        crossTrackError,
        originID,
        destinationID,
        destination,
        rangeToDestination,
        bearingToDestination,
        closingVelocity,
        isArrived,
        mode
      ) = payload
    else {
      Issue.record("expected .destinationMinimumData, got \(payload)")
      return
    }

    #expect(isValid)
    #expect(crossTrackError == .init(value: -0.5, unit: .nauticalMiles))
    #expect(originID == "KSQL")
    #expect(destinationID == "KOAK")
    #expect(destination.latitude == .init(value: 36.5, unit: .degrees))
    #expect(destination.longitude == .init(value: -122.25, unit: .degrees))
    #expect(rangeToDestination == .init(value: 15.5, unit: .nauticalMiles))
    #expect(bearingToDestination.angle == .init(value: 272.2, unit: .degrees))
    #expect(bearingToDestination.reference == .true)
    #expect(closingVelocity == .init(value: 13.5, unit: .knots))
    #expect(!isArrived)
    #expect(mode == .differential)
  }
}
