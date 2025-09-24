import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ZDASpec: AsyncSpec {
  override static func spec() {
    describe("8.3.106 ZDA") {
      it("parses the first example from the spec (corrected)") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(to: "$GPZDA,234500.00,09,06,1995,-12,45")
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .dateTime(let date, let timeZone) = payload else {
          fail("expected .dateTime, got \(payload)")
          return
        }

        let CHAT = TimeZone(secondsFromGMT: 12 * 60 * 60 + 45 * 60)!
        let expectedDateComponents = DateComponents(
          timeZone: CHAT,
          year: 1995,
          month: 6,
          day: 10,
          hour: 12,
          minute: 30
        )
        let expectedDate = Calendar.current.date(from: expectedDateComponents)!

        expect(date).to(equal(expectedDate))
        expect(timeZone).to(equal(CHAT))
      }

      it("parses the second example from the spec (corrected)") {
        let parser = SwiftNMEA()
        let sentence = applyChecksum(to: "$GPZDA,013000.00,11,06,1995,10,30")
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .dateTime(let date, let timeZone) = payload else {
          fail("expected .dateTime, got \(payload)")
          return
        }

        let KCT = TimeZone(secondsFromGMT: -10 * 60 * 60 - 30 * 60)!
        let expectedDateComponents = DateComponents(
          timeZone: KCT,
          year: 1995,
          month: 6,
          day: 10,
          hour: 15,
          minute: 0
        )
        let expectedDate = Calendar.current.date(from: expectedDateComponents)!

        expect(date).to(equal(expectedDate))
        expect(timeZone).to(equal(KCT))
      }
    }
  }
}
