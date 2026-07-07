import Foundation
import Testing

import SwiftDSE

@Suite("PositionEnhancement")
struct PositionEnhancementTests {
  // MARK: - PositionEnhancement

  @Test("round-trips through its raw value")
  func roundTripsThroughItsRawValue() throws {
    let enhancement = PositionEnhancement(rawValue: "12345678")
    #expect(enhancement != nil)
    #expect(enhancement?.rawValue == "12345678")
  }

  @Test("rejects raw values that are not eight digits")
  func rejectsRawValuesThatAreNotEightDigits() throws {
    #expect(PositionEnhancement(rawValue: "12345") == nil)
    #expect(PositionEnhancement(rawValue: "1234567890") == nil)
  }

  // MARK: - PositionSourceDatum

  @Test("round-trips through its raw value, including the datum digits")
  func roundTripsThroughItsRawValueIncludingTheDatumDigits() throws {
    let sourceDatum = PositionSourceDatum(rawValue: "015500")
    #expect(sourceDatum != nil)
    #expect(sourceDatum?.source == .differentialGPS)
    #expect(sourceDatum?.fixResolution == 5.5)
    #expect(sourceDatum?.datum == .WGS84)
    #expect(sourceDatum?.rawValue == "015500")
  }

  @Test("rejects raw values that are not six digits")
  func rejectsRawValuesThatAreNotSixDigits() throws {
    #expect(PositionSourceDatum(rawValue: "0155") == nil)
  }
}
