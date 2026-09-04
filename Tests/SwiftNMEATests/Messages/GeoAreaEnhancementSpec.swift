import Foundation
import SwiftDSE
import Testing

@Suite
struct `GeoAreaEnhancement tests` {
  // lat 12.34, lon 56.78, Δlat 13.24, Δlon 57.68, speed 22.4 kt, course 180.1°
  private let bothPresent = "123456781324576802241801"
  // speed sub-field (chars 17–20) replaced by the "no data" sentinel
  private let noSpeed = "1234567813245768----1801"
  // course sub-field (chars 21–24) replaced by the "no data" sentinel
  private let noCourse = "12345678132457680224----"

  // MARK: - decoding

  @Test
  func `reads speed and course when present`() {
    let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
    #expect(enhancement?.speed == .init(value: 22.4, unit: .knots))
    #expect(enhancement?.course == .init(value: 180.1, unit: .degrees))
  }

  @Test
  func `reads a missing speed estimate as nil`() {
    let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
    #expect(enhancement?.speed == nil)
    #expect(enhancement?.course == .init(value: 180.1, unit: .degrees))
  }

  @Test
  func `reads a missing course estimate as nil`() {
    let enhancement = GeoAreaEnhancement(rawValue: noCourse)
    #expect(enhancement?.speed == .init(value: 22.4, unit: .knots))
    #expect(enhancement?.course == nil)
  }

  @Test
  func `rejects a field that is not 24 characters`() {
    #expect(GeoAreaEnhancement(rawValue: "1234") == nil)
  }

  // MARK: - round trip

  @Test
  func `preserves speed and course when present`() {
    let enhancement = GeoAreaEnhancement(rawValue: bothPresent)
    #expect(enhancement?.rawValue == bothPresent)
  }

  @Test
  func `preserves a missing speed estimate`() {
    let enhancement = GeoAreaEnhancement(rawValue: noSpeed)
    #expect(enhancement?.rawValue == noSpeed)
  }

  @Test
  func `preserves a missing course estimate`() {
    let enhancement = GeoAreaEnhancement(rawValue: noCourse)
    #expect(enhancement?.rawValue == noCourse)
  }
}
