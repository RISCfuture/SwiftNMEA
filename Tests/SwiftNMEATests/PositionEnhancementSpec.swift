import Foundation
import Nimble
import Quick

import SwiftDSE

final class PositionEnhancementSpec: AsyncSpec {
  override static func spec() {
    describe("PositionEnhancement") {
      it("round-trips through its raw value") {
        let enhancement = PositionEnhancement(rawValue: "12345678")
        expect(enhancement).toNot(beNil())
        expect(enhancement?.rawValue).to(equal("12345678"))
      }

      it("rejects raw values that are not eight digits") {
        expect(PositionEnhancement(rawValue: "12345")).to(beNil())
        expect(PositionEnhancement(rawValue: "1234567890")).to(beNil())
      }
    }

    describe("PositionSourceDatum") {
      it("round-trips through its raw value, including the datum digits") {
        let sourceDatum = PositionSourceDatum(rawValue: "015500")
        expect(sourceDatum).toNot(beNil())
        expect(sourceDatum?.source).to(equal(.differentialGPS))
        expect(sourceDatum?.fixResolution).to(equal(5.5))
        expect(sourceDatum?.datum).to(equal(.WGS84))
        expect(sourceDatum?.rawValue).to(equal("015500"))
      }

      it("rejects raw values that are not six digits") {
        expect(PositionSourceDatum(rawValue: "0155")).to(beNil())
      }
    }
  }
}
