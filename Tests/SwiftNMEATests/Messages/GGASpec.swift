import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class GGASpec: AsyncSpec {
    override static func spec() {
        describe("8.3.35 GGA") {
            it("parses a sentence") {
                let parser = SwiftNMEA(),
                    time = Date(timeIntervalSinceNow: -2),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .GPS, format: .GPSFix,
                        fields: [hmsFractionFormatter.string(from: time),
                                 "3730.00", "N", "12115.00", "W",
                                 2, 11, 0.5,
                                 104.5, "M",
                                 1.1, "M",
                                 3.5, "0123"]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .GPSFix(position, actualTime, quality, numSatellites, HDOP, geoidalSeparation, DGPSAge, DGPSReferenceStationID) = payload else {
                    fail("expected .GNSSAccuracyIntegrity, got \(payload)")
                    return
                }

                expect(position.latitude).to(equal(.init(value: 37.5, unit: .degrees)))
                expect(position.longitude).to(equal(.init(value: -121.25, unit: .degrees)))
                expect(position.altitude).to(equal(.init(value: 104.5, unit: .meters)))
                expect(actualTime).to(beCloseTo(time, within: 0.01))
                expect(quality).to(equal(.differentialSPS))
                expect(numSatellites).to(equal(11))
                expect(HDOP).to(equal(0.5))
                expect(geoidalSeparation).to(equal(.init(value: 1.1, unit: .meters)))
                expect(DGPSAge).to(equal(.init(value: 3.5, unit: .seconds)))
                expect(DGPSReferenceStationID).to(equal(123))
            }

            it("parses a sentence from a STA8089FG") {
                let parser = SwiftNMEA(),
                    sentence = "$GPGGA,235944.000,0000.00000,N,00000.00000,E,0,00,99.0,100.00,M,0.0,M,,*61\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .GPSFix(position, _, quality, numSatellites, HDOP, geoidalSeparation, DGPSAge, DGPSReferenceStationID) = payload else {
                    fail("expected .GNSSAccuracyIntegrity, got \(payload)")
                    return
                }

                expect(position.latitude).to(equal(.init(value: 0, unit: .degrees)))
                expect(position.longitude).to(equal(.init(value: 0, unit: .degrees)))
                expect(quality).to(equal(.invalid))
                expect(numSatellites).to(equal(0))
                expect(HDOP).to(equal(99.0))
                expect(geoidalSeparation).to(equal(.init(value: 0, unit: .meters)))
                expect(position.altitude).to(equal(.init(value: 100, unit: .meters)))
                expect(DGPSAge).to(beNil())
                expect(DGPSReferenceStationID).to(beNil())
            }
        }
    }
}
