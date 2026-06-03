import Foundation
import Nimble
import Quick
import SwiftDSE

final class GeoAreaEnhancementSpec: AsyncSpec {
  override static func spec() {
    describe("GeoAreaEnhancement") {
      // lat 12.34, lon 56.78, Δlat 13.24, Δlon 57.68, speed 22.4 kt, course 180.1°
      let bothPresent = "123456781324576802241801"
      // speed sub-field (chars 17–20) replaced by the "no data" sentinel
      let noSpeed = "1234567813245768----1801"
      // course sub-field (chars 21–24) replaced by the "no data" sentinel
      let noCourse = "12345678132457680224----"

      describe("decoding") {
        it("reads speed and course when present") {
          let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
          expect(enhancement?.speed).to(equal(.init(value: 22.4, unit: .knots)))
          expect(enhancement?.course).to(equal(.init(value: 180.1, unit: .degrees)))
        }

        it("reads a missing speed estimate as nil") {
          let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
          expect(enhancement?.speed).to(beNil())
          expect(enhancement?.course).to(equal(.init(value: 180.1, unit: .degrees)))
        }

        it("reads a missing course estimate as nil") {
          let enhancement = GeoAreaEnhancement(rawValue: noCourse)
          expect(enhancement?.speed).to(equal(.init(value: 22.4, unit: .knots)))
          expect(enhancement?.course).to(beNil())
        }

        it("rejects a field that is not 24 characters") {
          expect(GeoAreaEnhancement(rawValue: "1234")).to(beNil())
        }
      }

      describe("round trip") {
        it("preserves speed and course when present") {
          let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
          expect(enhancement?.rawValue).to(equal(bothPresent))
        }

        it("preserves a missing speed estimate") {
          let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
          expect(enhancement?.rawValue).to(equal(noSpeed))
        }

        it("preserves a missing course estimate") {
          let enhancement = GeoAreaEnhancement(rawValue: noCourse)
          expect(enhancement?.rawValue).to(equal(noCourse))
        }
      }
    }
  }
}
