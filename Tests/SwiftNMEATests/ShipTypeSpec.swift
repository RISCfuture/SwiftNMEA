import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class ShipTypeSpec: AsyncSpec {
  override static func spec() {
    describe("AISLongRange.ShipType (M.1371-6 Table 51)") {
      it("parses and round-trips ship types added or changed in M.1371-6") {
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
          expect(AISLongRange.ShipType(rawValue: raw)).to(equal(expected))
          expect(expected.rawValue).to(equal(raw))
        }
      }

      it("returns nil for reserved ship-type codes") {
        // 08, 15, 25, 47, 68, 87, 95 are reserved for future use
        for raw in [8, 15, 25, 47, 68, 87, 95] {
          expect(AISLongRange.ShipType(rawValue: raw)).to(beNil())
        }
      }
    }
  }
}
