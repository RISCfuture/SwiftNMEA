import Foundation
import SwiftDSE
import Testing

@Suite
struct `GeoAreaEnhancement tests` {
  // MARK: - decoding

  @Test(arguments: EnhancementCase.all)
  func `reads the speed and course estimates`(_ testCase: EnhancementCase) {
    let enhancement = GeoAreaEnhancement(rawValue: testCase.rawValue)
    #expect(enhancement?.speed == testCase.speed)
    #expect(enhancement?.course == testCase.course)
  }

  @Test
  func `rejects a field that is not 24 characters`() {
    #expect(GeoAreaEnhancement(rawValue: "1234") == nil)
  }

  // MARK: - round trip

  @Test(arguments: EnhancementCase.all)
  func `preserves the field through a round trip`(_ testCase: EnhancementCase) {
    let enhancement = GeoAreaEnhancement(rawValue: testCase.rawValue)
    #expect(enhancement?.rawValue == testCase.rawValue)
  }

  /// A 24-character geographic-area enhancement field and the estimates it carries.
  ///
  /// Every case encodes lat 12.34, lon 56.78, Δlat 13.24, Δlon 57.68; they differ
  /// only in whether the speed and course sub-fields hold the "no data" sentinel.
  struct EnhancementCase: Sendable, CustomTestStringConvertible {
    static let all: [Self] = [
      .init(
        name: "speed and course present",
        rawValue: "123456781324576802241801",
        speed: .init(value: 22.4, unit: .knots),
        course: .init(value: 180.1, unit: .degrees)
      ),
      .init(
        name: "no speed estimate",
        rawValue: "1234567813245768----1801",
        speed: nil,
        course: .init(value: 180.1, unit: .degrees)
      ),
      .init(
        name: "no course estimate",
        rawValue: "12345678132457680224----",
        speed: .init(value: 22.4, unit: .knots),
        course: nil
      )
    ]

    let name: String
    let rawValue: String
    let speed: Measurement<UnitSpeed>?
    let course: Measurement<UnitAngle>?

    var testDescription: String { name }
  }
}
