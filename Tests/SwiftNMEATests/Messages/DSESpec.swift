import Foundation
import Nimble
import Quick

@testable import NMEACommon
@testable import SwiftNMEA

final class DSESpec: AsyncSpec {
  override static func spec() {
    describe("8.3.26 DSE") {
      describe(".parse") {
        it("parses a query and a reply") {
          let parser = SwiftNMEA()

          // MARK: Setup

          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                3, 1, "A", 1_234_567_890,
                "00", "23451234",
                "01", "015500"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                1, 1, "Q", 9_876_543_210,
                "00", nil,
                "05", nil
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                3, 2, "A", 1_234_567_890,
                "02", "C26",
                "02", "0224",
                "03", "1801"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                3, 3, nil, nil,
                "04", "ABC'123",
                "05", "123456781324576802241801",
                "06", "0112"
              ]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          // MARK: - Message 1

          expect(messages).to(haveCount(6))
          guard let payload1 = (messages[2] as? Message)?.payload else {
            fail("expected Message, got \(messages[2])")
            return
          }
          guard let payload2 = (messages[5] as? Message)?.payload else {
            fail("expected Message, got \(messages[5])")
            return
          }
          guard case .DSE(let type, let MMSI, let data) = payload2 else {
            fail("expected .DSE, got \(payload2)")
            return
          }

          expect(type).to(equal(.automatic))
          expect(MMSI).to(equal(123_456_789))
          expect(data).to(haveCount(8))

          // MARK: data 0 (enhancedPositionResolution)

          guard case .enhancedPositionResolution(let content) = data[0] else {
            fail("expected .enhancedPositionResolution, got \(data[0])")
            return
          }
          guard case .data(let enhancement) = content else {
            fail("expected .data, got \(content)")
            return
          }
          let testPos = Position(latitude: 37.5, longitude: -121.25)
          let refinedPos = enhancement.refine(position: testPos)
          expect(refinedPos.latitude.converted(to: .degrees).value).to(beCloseTo(37.5039083333))
          expect(refinedPos.longitude.converted(to: .degrees).value).to(beCloseTo(-121.2520566667))

          // MARK: data 1 (positionSourceDatum)

          guard case .positionSourceDatum(let content) = data[1] else {
            fail("expected .positionSourceDatum, got \(data[1])")
            return
          }
          guard case .data(let sourceDatum) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(sourceDatum.source).to(equal(.differentialGPS))
          expect(sourceDatum.fixResolution).to(equal(5.5))
          expect(sourceDatum.datum).to(equal(.WGS84))

          // MARK: data 2 (speed noDataAvailable)

          guard case .speed(let content) = data[2] else {
            fail("expected .speed, got \(data[2])")
            return
          }
          expect(content).to(equal(.noDataAvailable))

          // MARK: data 3 (speed)

          guard case .speed(let content) = data[3] else {
            fail("expected .speed, got \(data[3])")
            return
          }
          guard case .data(let speed) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(speed.measurement).to(equal(.init(value: 22.4, unit: .knots)))

          // MARK: data 4 (course)

          guard case .course(let content) = data[4] else {
            fail("expected .course, got \(data[4])")
            return
          }
          guard case .data(let course) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(course.measurement).to(equal(.init(value: 180.1, unit: .degrees)))

          // MARK: data 5 (additional ID)

          guard case .additionalID(let content) = data[5] else {
            fail("expected .additionalID, git \(data[5])")
            return
          }
          guard case .data(let ID) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(ID.value).to(equal("ABC,123"))

          // MARK: data 6 (geo area)

          guard case .enhnancedGeoArea(let content) = data[6] else {
            fail("expected .enhnancedGeoArea, git \(data[6])")
            return
          }
          guard case .data(let enhancement) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(enhancement.latitudeRefinement).to(equal(.init(value: 12.34, unit: .arcMinutes)))
          expect(enhancement.longitudeRefinement).to(equal(.init(value: 56.78, unit: .arcMinutes)))
          expect(enhancement.deltaLatRefinement).to(equal(.init(value: 13.24, unit: .arcMinutes)))
          expect(enhancement.deltaLonRefinement).to(equal(.init(value: 57.68, unit: .arcMinutes)))
          expect(enhancement.speed).to(equal(.init(value: 22.4, unit: .knots)))
          expect(enhancement.course).to(equal(.init(value: 180.1, unit: .degrees)))
          let area = GeoArea(latitude: 37, longitude: -121, deltaLat: 3, deltaLon: 4)
          let refinedArea = enhancement.refine(area: area)
          expect(refinedArea.latitude.converted(to: .degrees).value).to(beCloseTo(37.2056666667))
          expect(refinedArea.longitude.converted(to: .degrees).value).to(beCloseTo(-121.9463333333))
          expect(refinedArea.deltaLat.converted(to: .degrees).value).to(beCloseTo(3.2206666667))
          expect(refinedArea.deltaLon.converted(to: .degrees).value).to(beCloseTo(4.9613333333))

          // MARK: data 7 (souls onboard)

          guard case .personsOnboard(let content) = data[7] else {
            fail("expected .personsOnboard, got \(data[7])")
            return
          }
          guard case .data(let souls) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(souls.value).to(equal(112))

          // MARK: - Message 2

          guard case .DSE(let type, let MMSI, let data) = payload1 else {
            fail("expected .DSE, got \(payload1)")
            return
          }
          expect(type).to(equal(.query))
          expect(MMSI).to(equal(987_654_321))
          expect(data).to(haveCount(2))

          // MARK: data 0

          guard case .enhancedPositionResolution(let content) = data[0] else {
            fail("expected .enhancedPositionResolution, got \(data[0])")
            return
          }
          expect(content).to(equal(.dataRequest))

          // MARK: data 1

          guard case .enhnancedGeoArea(let content) = data[1] else {
            fail("expected .enhancedPositionResolution, got \(data[1])")
            return
          }
          expect(content).to(equal(.dataRequest))
        }

        it("throws an error for a missing field") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                2, 1, "A", nil,
                "00", "23451234",
                "01", "015500"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                2, 2, "A", 1_234_567_890,
                "02", "C26",
                "02", "0224",
                "03", "1801"
              ]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(3))

          guard let error = messages[1] as? MessageError else {
            fail("expected MessageError, got \(messages[1])")
            return
          }
          expect(error.type).to(equal(.missingRequiredValue))
          expect(error.fieldNumber).to(equal(3))
        }

        it("throws an error for an incorrect sentence number") {
          let parser = SwiftNMEA()
          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                2, 1, "A", 1_234_567_890,
                "00", "23451234",
                "01", "015500"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                2, 3, "A", 1_234_567_890,
                "02", "C26",
                "02", "0224",
                "03", "1801"
              ]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(3))
          guard let error = messages[2] as? MessageError else {
            fail("expected MessageError, got \(messages[2])")
            return
          }
          expect(error.type).to(equal(.wrongSentenceNumber))
          expect(error.fieldNumber).to(equal(1))
        }

        it("parses the example from the spec") {
          let parser = SwiftNMEA()
          let sentence = "$CVDSE,1,1,A,3601234560,00,12345678*0C\r\n"
          let data = sentence.data(using: .ascii)!
          let messages = try await parser.parse(data: data)

          expect(messages).to(haveCount(2))
          guard let message = messages[1] as? Message else {
            fail("expected Message, got \(messages[1])")
            return
          }
          guard case .DSE(let type, let MMSI, let data) = message.payload else {
            fail("expected .DSE, got \(message)")
            return
          }

          expect(type).to(equal(.automatic))
          expect(MMSI).to(equal(360_123_456))

          expect(data).to(haveCount(1))
          guard case .enhancedPositionResolution(let value) = data[0] else {
            fail("expected .enhancedPositionResolution, got \(data[0])")
            return
          }
          guard case .data(let refinement) = value else {
            fail("expected .data, got \(value)")
            return
          }
          expect(refinement.latitudeRefinement.value).to(beCloseTo(0.1234, within: 0.000001))
          expect(refinement.longitudeRefinement.value).to(beCloseTo(0.5678, within: 0.000001))
        }
      }

      describe(".flush") {
        it("flushes incomplete sentences") {
          let parser = SwiftNMEA()

          // MARK: Setup

          let sentences = [
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                3, 1, "A", 1_234_567_890,
                "00", "23451234",
                "01", "015500"
              ]
            ),
            createSentence(
              delimiter: .parametric,
              talker: .commDSC,
              format: .DSE,
              fields: [
                3, 2, "A", 1_234_567_890,
                "02", "C26",
                "02", "0224",
                "03", "1801"
              ]
            )
          ]
          let data = sentences.joined().data(using: .ascii)!

          let parsed = try await parser.parse(data: data)
          expect(parsed).to(haveCount(2))
          let messages = try await parser.flush(includeIncomplete: true)

          // MARK: - Message 1

          expect(messages).to(haveCount(1))

          guard let message = messages[0] as? Message else {
            fail("expected Message, got \(messages[0])")
            return
          }
          guard case .DSE(let type, let MMSI, let data) = message.payload else {
            fail("expected .DSE, got \(message)")
            return
          }

          expect(type).to(equal(.automatic))
          expect(MMSI).to(equal(123_456_789))
          expect(data).to(haveCount(5))

          // MARK: data 0 (enhancedPositionResolution)

          guard case .enhancedPositionResolution(let content) = data[0] else {
            fail("expected .enhancedPositionResolution, got \(data[0])")
            return
          }
          guard case .data(let enhancement) = content else {
            fail("expected .data, got \(content)")
            return
          }
          let testPos = Position(latitude: 37.5, longitude: -121.25)
          let refinedPos = enhancement.refine(position: testPos)
          expect(refinedPos.latitude.converted(to: .degrees).value).to(beCloseTo(37.5039083333))
          expect(refinedPos.longitude.converted(to: .degrees).value).to(beCloseTo(-121.2520566667))

          // MARK: data 1 (positionSourceDatum)

          guard case .positionSourceDatum(let content) = data[1] else {
            fail("expected .positionSourceDatum, got \(data[1])")
            return
          }
          guard case .data(let sourceDatum) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(sourceDatum.source).to(equal(.differentialGPS))
          expect(sourceDatum.fixResolution).to(equal(5.5))
          expect(sourceDatum.datum).to(equal(.WGS84))

          // MARK: data 2 (speed noDataAvailable)

          guard case .speed(let content) = data[2] else {
            fail("expected .speed, got \(data[2])")
            return
          }
          expect(content).to(equal(.noDataAvailable))

          // MARK: data 3 (speed)

          guard case .speed(let content) = data[3] else {
            fail("expected .speed, got \(data[3])")
            return
          }
          guard case .data(let speed) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(speed.measurement).to(equal(.init(value: 22.4, unit: .knots)))

          // MARK: data 4 (course)

          guard case .course(let content) = data[4] else {
            fail("expected .course, got \(data[4])")
            return
          }
          guard case .data(let course) = content else {
            fail("expected .data, got \(content)")
            return
          }
          expect(course.measurement).to(equal(.init(value: 180.1, unit: .degrees)))
        }
      }
    }
  }
}
