import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class RRTSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.85 RRT") {
      it("parses a status report for a monitored route") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .routeTransferReport,
          fields: ["M", "KSQLKDWA", "1.2", "OAK30", "A", "P"]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
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
          fail("expected .routeTransferReport, got \(payload)")
          return
        }
        expect(transferType).to(equal(.monitored))
        expect(name).to(equal("KSQLKDWA"))
        expect(version).to(equal("1.2"))
        expect(currentWaypoint).to(equal("OAK30"))
        expect(fileStatus).to(equal(.success))
        expect(applicationStatus).to(equal(.pending))
      }

      it("parses an empty query response with null fields") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .routeTransferReport,
          fields: ["M", nil, nil, nil, nil, nil]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
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
          fail("expected .routeTransferReport, got \(payload)")
          return
        }
        expect(transferType).to(equal(.monitored))
        expect(name).to(beNil())
        expect(version).to(beNil())
        expect(currentWaypoint).to(beNil())
        expect(fileStatus).to(beNil())
        expect(applicationStatus).to(beNil())
      }

      it("throws an error for an invalid transfer type") {
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
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
