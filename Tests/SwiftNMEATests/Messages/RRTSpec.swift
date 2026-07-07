import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.85 RRT")
struct RRTTests {
  @Test("parses a status report for a monitored route")
  func parsesAStatusReportForAMonitoredRoute() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .routeTransferReport,
      fields: ["M", "KSQLKDWA", "1.2", "OAK30", "A", "P"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .routeTransferReport(
        transferType,
        name,
        version,
        currentWaypoint,
        fileStatus,
        applicationStatus
      ) = payload
    else {
      Issue.record("expected .routeTransferReport, got \(payload)")
      return
    }
    #expect(transferType == .monitored)
    #expect(name == "KSQLKDWA")
    #expect(version == "1.2")
    #expect(currentWaypoint == "OAK30")
    #expect(fileStatus == .success)
    #expect(applicationStatus == .pending)
  }

  @Test("parses an empty query response with null fields")
  func parsesAnEmptyQueryResponseWithNullFields() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .routeTransferReport,
      fields: ["M", nil, nil, nil, nil, nil]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .routeTransferReport(
        transferType,
        name,
        version,
        currentWaypoint,
        fileStatus,
        applicationStatus
      ) = payload
    else {
      Issue.record("expected .routeTransferReport, got \(payload)")
      return
    }
    #expect(transferType == .monitored)
    #expect(name == nil)
    #expect(version == nil)
    #expect(currentWaypoint == nil)
    #expect(fileStatus == nil)
    #expect(applicationStatus == nil)
  }

  @Test("throws an error for an invalid transfer type")
  func throwsAnErrorForAnInvalidTransferType() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .routeTransferReport,
      fields: ["X", "KSQLKDWA", "1.2", "OAK30", "A", "P"]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    guard let error = messages[1] as? MessageError else {
      Issue.record("expected MessageError, got \(messages[1])")
      return
    }
    #expect(error.type == .unknownValue)
  }
}
