import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GLLSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.36 GLL") {
      it("parses the example from the spec") {
        let parser = SwiftNMEA()
        let sentence = "$LCGLL,4728.31,N,12254.25,W,091342,A,A*4C\r\n"
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .geoPosition(let position, let time, let isValid, let mode) = payload else {
          fail("expected .geoPosition, got \(payload)")
          return
        }

        expect(position.latitude.value).to(beCloseTo(47.4718333333, within: 0.000001))
        expect(position.longitude.value).to(beCloseTo(-122.9041666667, within: 0.000001))
        expect(isValid).to(beTrue())
        expect(mode).to(equal(.autonomous))

        let components = Calendar.current.dateComponents(in: .gmt, from: time)
        expect(components.hour).to(equal(9))
        expect(components.minute).to(equal(13))
        expect(components.second).to(equal(42))
      }
    }
  }
}
