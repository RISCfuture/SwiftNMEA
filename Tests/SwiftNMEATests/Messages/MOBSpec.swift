import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class MOBSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.64 MOB") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .manOverboard,
          fields: [
            "000FF",
            "A",
            "120000",
            1,
            3,
            "120530",
            "3730.00", "N", "12115.00", "W",
            90,
            5,
            123_456_789,
            0
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .manOverboard(
            emitterID,
            status,
            activationTime,
            positionSource,
            daysSinceActivation,
            positionTime,
            position,
            courseOverGround,
            speedOverGround,
            MMSI,
            batteryStatus
          ) = payload
        else {
          fail("expected .manOverboard, got \(payload)")
          return
        }

        expect(emitterID).to(equal(0xFF))
        expect(status).to(equal(.activated))
        expect(positionSource).to(equal(.reportedByEmitter))
        expect(daysSinceActivation).to(equal(3))
        expect(position.latitude).to(equal(.init(value: 37.5, unit: .degrees)))
        expect(position.longitude).to(equal(.init(value: -121.25, unit: .degrees)))
        expect(courseOverGround.angle).to(equal(.init(value: 90, unit: .degrees)))
        expect(courseOverGround.reference).to(equal(.true))
        expect(speedOverGround).to(equal(.init(value: 5, unit: .knots)))
        expect(MMSI).to(equal(123_456_789))
        expect(batteryStatus).to(equal(.good))

        let activation = Calendar.current.dateComponents(in: .gmt, from: activationTime)
        expect(activation.hour).to(equal(12))
        expect(activation.minute).to(equal(0))
        expect(activation.second).to(equal(0))

        let positioned = Calendar.current.dateComponents(in: .gmt, from: positionTime)
        expect(positioned.hour).to(equal(12))
        expect(positioned.minute).to(equal(5))
        expect(positioned.second).to(equal(30))
      }

      it("parses a sentence with unavailable values") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .manOverboard,
          fields: [
            nil,
            "T",
            "010203",
            0,
            0,
            "010203",
            "3730.00", "N", "12115.00", "W",
            0,
            0,
            nil,
            nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case let .manOverboard(
            emitterID,
            status,
            _,
            positionSource,
            _,
            _,
            _,
            _,
            _,
            MMSI,
            batteryStatus
          ) = payload
        else {
          fail("expected .manOverboard, got \(payload)")
          return
        }

        expect(emitterID).to(beNil())
        expect(status).to(equal(.test))
        expect(positionSource).to(equal(.estimatedByVessel))
        expect(MMSI).to(beNil())
        expect(batteryStatus).to(beNil())
      }

      it("throws an error for an unknown position source") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .integratedNavigation,
          format: .manOverboard,
          fields: [
            "000FF",
            "A",
            "120000",
            7,
            3,
            "120530",
            "3730.00", "N", "12115.00", "W",
            90,
            5,
            123_456_789,
            0
          ]
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
