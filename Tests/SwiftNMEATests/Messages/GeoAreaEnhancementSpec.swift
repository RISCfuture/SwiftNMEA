import Foundation
import SwiftDSE
import Testing

@Suite("GeoAreaEnhancement")
struct GeoAreaEnhancementTests {
  // lat 12.34, lon 56.78, Δlat 13.24, Δlon 57.68, speed 22.4 kt, course 180.1°
  private let bothPresent = "123456781324576802241801"
  // speed sub-field (chars 17–20) replaced by the "no data" sentinel
  private let noSpeed = "1234567813245768----1801"
  // course sub-field (chars 21–24) replaced by the "no data" sentinel
  private let noCourse = "12345678132457680224----"

  // MARK: - decoding

  @Test("reads speed and course when present")
  func readsSpeedAndCourseWhenPresent() {
    let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
    #expect(enhancement?.speed == .init(value: 22.4, unit: .knots))
    #expect(enhancement?.course == .init(value: 180.1, unit: .degrees))
  }

  @Test("reads a missing speed estimate as nil")
  func readsAMissingSpeedEstimateAsNil() {
    let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
    #expect(enhancement?.speed == nil)
    #expect(enhancement?.course == .init(value: 180.1, unit: .degrees))
  }

  @Test("reads a missing course estimate as nil")
  func readsAMissingCourseEstimateAsNil() {
    let enhancement = GeoAreaEnhancement(rawValue: noCourse)
    #expect(enhancement?.speed == .init(value: 22.4, unit: .knots))
    #expect(enhancement?.course == nil)
  }

  @Test("rejects a field that is not 24 characters")
  func rejectsAFieldThatIsNot24Characters() {
    #expect(GeoAreaEnhancement(rawValue: "1234") == nil)
  }

  // MARK: - round trip

  @Test("preserves speed and course when present")
  func preservesSpeedAndCourseWhenPresent() {
    let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
    #expect(enhancement?.rawValue == bothPresent)
  }

  @Test("preserves a missing speed estimate")
  func preservesAMissingSpeedEstimate() {
    let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
    #expect(enhancement?.rawValue == noSpeed)
  }

  @Test("preserves a missing course estimate")
  func preservesAMissingCourseEstimate() {
    let enhancement = GeoAreaEnhancement(rawValue: noCourse)
    #expect(enhancement?.rawValue == noCourse)
  }
}
