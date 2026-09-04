import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `AISLongRange.ShipType (M.1371-6 Table 51)` {
  @Test
  func `parses and round-trips ship types added or changed in M.1371-6`() throws {
    let cases: [(Int, AISLongRange.ShipType)] = [
      (4, .specialPurpose(.iceBreaker)),
      (11, .supportVessel(.FPSO)),
      (35, .vessel(operation: .military)),
      (38, .vessel(operation: .trawler)),
      (39, .vessel(operation: .patrol)),
      (45, .highSpeedCraft(.passengers)),
      (46, .highSpeedCraft(.rollOnRollOff)),
      (56, .localVessel1),
      (65, .passengerShip(.cruise)),
      (76, .cargoShip(.containerShip)),
      (86, .tanker(.integratedTugBarge))
    ]
    for (raw, expected) in cases {
      #expect(AISLongRange.ShipType(rawValue: raw) == expected)
      #expect(expected.rawValue == raw)
    }
  }

  @Test
  func `returns nil for reserved ship-type codes`()
    throws
  {
    // 08, 15, 25, 47, 68, 87, 95 are reserved for future use
    for raw in [8, 15, 25, 47, 68, 87, 95] {
      #expect(AISLongRange.ShipType(rawValue: raw) == nil)
    }
  }
}
