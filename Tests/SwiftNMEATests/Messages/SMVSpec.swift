import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class SMVSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.97 SMV") {
      describe(".parse") {
        it("parses a single-sentence distress relay") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETVesselDistress,
            fields: [
              1, nil, 4, 123_123, 123_456_789, "TEST56",
              "1234.56", "N", "12345.67", "W",
              2018, 1, 22, 12, 34, "D"
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
            case let .safetyNETVesselDistress(
              uniqueMessageNumber,
              identifier,
              mmsi,
              vesselName,
              position,
              positionTime,
              status
            ) = payload
          else {
            fail("expected .safetyNETVesselDistress, got \(payload)")
            return
          }

          expect(uniqueMessageNumber).to(equal(123_123))
          expect(identifier).to(equal(4))
          expect(mmsi).to(equal(123_456_789))
          expect(vesselName).to(equal("TEST56"))
          expect(position).to(equal(.init(latitude: (12, 34.56), longitude: (-123, 45.67))))
          let components = DateComponents(
            timeZone: .gmt,
            year: 2018,
            month: 1,
            day: 22,
            hour: 12,
            minute: 34
          )
          expect(positionTime).to(equal(calendar.date(from: components)))
          expect(status).to(equal(.distressActive))
        }

        it("parses a single-sentence cancellation with null optional fields") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETVesselDistress,
            fields: [
              1, nil, 5, 12, nil, nil,
              nil, nil, nil, nil,
              nil, nil, nil, nil, nil, "C"
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
            case let .safetyNETVesselDistress(
              uniqueMessageNumber,
              identifier,
              mmsi,
              vesselName,
              position,
              positionTime,
              status
            ) = payload
          else {
            fail("expected .safetyNETVesselDistress, got \(payload)")
            return
          }

          expect(uniqueMessageNumber).to(equal(12))
          expect(identifier).to(equal(5))
          expect(mmsi).to(beNil())
          expect(vesselName).to(beNil())
          expect(position).to(beNil())
          expect(positionTime).to(beNil())
          expect(status).to(equal(.distressCancelled))
        }

        it("assembles a two-sentence message with position and name in separate sentences") {
          let parser = SwiftNMEA()
          let sentences = [
            applyChecksum(to: "$CSSMV,2,1,5,12,123456789,,1234.56,N,12345.67,W,2018,01,23,12,34,D"),
            applyChecksum(to: "$CSSMV,2,2,5,12,123456789,MAXIMUM LENGTH FOR VESSEL NAME,,,,,,,,,,D")
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          // two echoed sentences, then the assembled message on the last sentence
          expect(messages).to(haveCount(3))
          guard let payload = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          guard
            case let .safetyNETVesselDistress(
              uniqueMessageNumber,
              identifier,
              mmsi,
              vesselName,
              position,
              _,
              status
            ) = payload
          else {
            fail("expected .safetyNETVesselDistress, got \(payload)")
            return
          }

          expect(uniqueMessageNumber).to(equal(12))
          expect(identifier).to(equal(5))
          expect(mmsi).to(equal(123_456_789))
          expect(vesselName).to(equal("MAXIMUM LENGTH FOR VESSEL NAME"))
          expect(position).to(equal(.init(latitude: (12, 34.56), longitude: (-123, 45.67))))
          expect(status).to(equal(.distressActive))
        }

        it("throws an error for a null sentence number in a multi-sentence message") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETVesselDistress,
            fields: [
              2, nil, 4, 123_123, 123_456_789, "TEST56",
              "1234.56", "N", "12345.67", "W",
              2018, 1, 22, 12, 34, "D"
            ]
          )
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(1))
        }

        it("throws an error for an unknown distress status value") {
          let parser = SwiftNMEA()
          let sentence = createSentence(
            delimiter: .parametric,
            talker: .commSatellite,
            format: .safetyNETVesselDistress,
            fields: [
              1, nil, 4, 123_123, 123_456_789, "TEST56",
              "1234.56", "N", "12345.67", "W",
              2018, 1, 22, 12, 34, "X"
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
}
