import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class GRSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.38 GRS") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let time = Date(timeIntervalSinceNow: -2)
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GPS,
          format: .GNSSRangeResiduals,
          fields: [
            hmsFractionFormatter.string(from: time), 0,
            0.1, 0.2, 0.3, 0.4, 0.5,
            1, 7
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case .GNSSRangeResiduals(let residuals, let actualTime, let recomputed) = payload
        else {
          fail("expected .GNSSRangeResiduals, got \(payload)")
          return
        }

        expect(residuals).to(
          equal([
            .GPS(0, signal: .L5_I): .init(value: 0.1, unit: .meters),
            .GPS(1, signal: .L5_I): .init(value: 0.2, unit: .meters),
            .GPS(2, signal: .L5_I): .init(value: 0.3, unit: .meters),
            .GPS(3, signal: .L5_I): .init(value: 0.4, unit: .meters),
            .GPS(4, signal: .L5_I): .init(value: 0.5, unit: .meters)
          ])
        )
        expect(actualTime).to(beCloseTo(time, within: 0.01))
        expect(recomputed).to(beFalse())
      }
    }
  }
}
