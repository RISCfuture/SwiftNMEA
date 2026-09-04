import Foundation
import Testing

import SwiftDSE

@Suite
struct `PositionEnhancement tests` {
  // MARK: - PositionEnhancement

  @Test
  func `round-trips through its raw value`() throws {
    let enhancement = PositionEnhancement(rawValue: "12345678")
    #expect(enhancement != nil)
    #expect(enhancement?.rawValue == "12345678")
  }

  @Test
  func `rejects raw values that are not eight digits`() throws {
    #expect(PositionEnhancement(rawValue: "12345") == nil)
    #expect(PositionEnhancement(rawValue: "1234567890") == nil)
  }

  // MARK: - PositionSourceDatum

  @Test
  func `round-trips through its raw value, including the datum digits`() throws {
    let sourceDatum = PositionSourceDatum(rawValue: "015500")
    #expect(sourceDatum != nil)
    #expect(sourceDatum?.source == .differentialGPS)
    #expect(sourceDatum?.fixResolution == 5.5)
    #expect(sourceDatum?.datum == .WGS84)
    #expect(sourceDatum?.rawValue == "015500")
  }

  @Test
  func `rejects raw values that are not six digits`() throws {
    #expect(PositionSourceDatum(rawValue: "0155") == nil)
  }
}
