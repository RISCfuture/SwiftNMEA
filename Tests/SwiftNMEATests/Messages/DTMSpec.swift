import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class DTMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.27 DTM") {
      it("parses a sentence") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .GNSS,
          format: .datumReference,
          fields: [
            "999", "F",
            "13.2", "N",
            "22.8", "W",
            "-12.5",
            "W84", nil
          ]
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .datumReference(
            let localDatum,
            let latitudeOffset,
            let longitudeOffset,
            let altitudeOffset,
            let referenceDatum
          ) = payload
        else {
          fail("expected .datumReference, got \(payload)")
          return
        }

        expect(localDatum).to(equal(.userDefined(subdivision: "F")))
        expect(latitudeOffset).to(equal(.init(value: 13.2, unit: .arcMinutes)))
        expect(longitudeOffset).to(equal(.init(value: -22.8, unit: .arcMinutes)))
        expect(altitudeOffset).to(equal(.init(value: -12.5, unit: .meters)))
        expect(referenceDatum).to(equal(.WGS84))
      }
    }
  }
}
