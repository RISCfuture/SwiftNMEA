import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class WATSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.99 WAT") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -15)
        let sentence = createSentence(
          delimiter: .parametric, talker: .waterLevelDetection, format: .waterLevel,
          fields: [
            "E", hmsFractionFormatter.string(from: time),
            "WL", "CA", "01", 3,
            "H", "O", "Detector CA01",
          ])
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .waterLevel(
            let messageType, let actualTime, let systemType, let location1, let location2,
            let number, let alarmCondition, let isOverriden, let description) = payload
        else {
          fail("expected .waterLevel, got \(payload)")
          return
        }

        expect(messageType).to(equal(.event))
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(systemType).to(equal(.waterLevel))
        expect(location1).to(equal("CA"))
        expect(location2).to(equal("01"))
        expect(number).to(equal(3))
        expect(alarmCondition).to(equal(.alarmHigh))
        expect(isOverriden).to(beTrue())
        expect(description).to(equal("Detector CA01"))
      }
    }
  }
}
