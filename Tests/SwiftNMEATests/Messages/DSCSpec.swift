import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class DSCSpec: AsyncSpec {
    override static func spec() {
        describe("8.3.25 DSC") {
            it("parses the distress example from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$CVDSC,12,3601234560,12,05,00,1474712519,0817,,,S,E,*51\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .DSC(format, MMSI, area, category, message1_1, message1_2, message2, message3, distressMMSI, distressMMSINature, acknowledgement, expansion) = payload else {
                    fail("expected .DSC, got \(payload)")
                    return
                }

                let nature = DSC.DistressNature(rawValue: message1_1!),
                    commType = DSC.DistressCommunicationDesired(rawValue: message1_2!),
                    position = DSC.distressCoordinates(from: message2!),
                    time = DSC.time(from: message3!)

                expect(format).to(equal(.distress))
                expect(MMSI).to(equal(360123456))
                expect(area).to(beNil())
                expect(category).to(equal(.distress))
                expect(nature).to(equal(.sinking))
                expect(commType).to(equal(.F3E_G3E_allModesTP))
                expect(position!.latitude.value).to(beCloseTo(47.7833333333, within: 0.01))
                expect(position!.longitude.value).to(beCloseTo(-125.3166666667, within: 0.01))
                expect(distressMMSI).to(beNil())
                expect(distressMMSINature).to(beNil())
                expect(acknowledgement).to(equal(.end))
                expect(expansion).to(beTrue())

                let components = Calendar.current.dateComponents(in: .gmt, from: time!)
                expect(components.hour).to(equal(8))
                expect(components.minute).to(equal(17))
            }

            it("parses the relay example from the spec") {
                let parser = SwiftNMEA(),
                sentence = "$CTDSC,16,0112345670,12,12,09,1474712219,1234,9991212120,00,S*19\r\n",
                data = sentence.data(using: .ascii)!,
                messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .DSC(format, MMSI, area, category, message1_1,
                                    message1_2, message2, message3, distressMMSI,
                                    distressMMSINature, acknowledgement,
                                    expansion) = message.payload else {
                    fail("expected .DSC, got \(message)")
                    return
                }

                expect(format).to(equal(.allShips))
                expect(MMSI).to(equal(011234567))
                expect(area).to(beNil())
                expect(category).to(equal(.distress))
                expect(message1_1).to(equal("12"))
                expect(message1_2).to(equal("09"))
                expect(message2).to(equal("1474712219"))
                expect(message3).to(equal("1234"))
                expect(distressMMSI).to(equal(999121212))
                expect(distressMMSINature).to(equal(.fire))
                expect(acknowledgement).to(equal(.end))
                expect(expansion).to(beFalse())
            }

            it("parses the safety call example from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$CTDSC,16,0112345670,08,09,26,041250,,,,S*11\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .DSC(format, MMSI, area, category, message1_1,
                                    message1_2, message2, message3, distressMMSI,
                                    distressMMSINature, acknowledgement,
                                    expansion) = message.payload else {
                    fail("expected .DSC, got \(message)")
                    return
                }

                expect(format).to(equal(.allShips))
                expect(MMSI).to(equal(011234567))
                expect(area).to(beNil())
                expect(category).to(equal(.safety))
                expect(message1_1).to(equal("09"))
                expect(message1_2).to(equal("26"))
                expect(message2).to(equal("041250"))
                expect(message3).to(beNil())
                expect(distressMMSI).to(beNil())
                expect(distressMMSINature).to(beNil())
                expect(acknowledgement).to(equal(.end))
                expect(expansion).to(beFalse())
            }

            it("parses a geographic sentence") {
                let parser = SwiftNMEA(),
                    sentence = createSentence(
                        delimiter: .parametric, talker: .commDSC, format: .DSC,
                        fields: [
                            "02", 1351210102, "00",
                            12, 26, 41252165, 10500012345,
                            9876543210, "05", "B", ""
                        ]),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .DSC(format, MMSI, area, category, message1_1, message1_2, message2, message3, distressMMSI, distressMMSINature, acknowledgement, expansion) = payload else {
                    fail("expected .DSC, got \(payload)")
                    return
                }

                let telecommand1 = DSC.Telecommand1(rawValue: message1_1!),
                    telecommand2 = DSC.Telecommand2(rawValue: message1_2!),
                    freq = DSC.FrequencyChannel(rawValue: message2!),
                    phone = DSC.networkNumber(from: message3!)

                expect(format).to(equal(.geographic))
                expect(MMSI).to(beNil())
                expect(area).to(equal(.init(latitude: .init(value: 35, unit: .degrees),
                                            longitude: .init(value: -121, unit: .degrees),
                                            deltaLat: .init(value: 1, unit: .degrees),
                                            deltaLon: .init(value: 2, unit: .degrees))))
                expect(category).to(equal(.routine))
                expect(telecommand1).to(equal(.distressRelay))
                expect(telecommand2).to(equal(.noInformation))
                expect(freq).to(equal(.frequency(.init(value: 12_521_650, unit: .hertz))))
                expect(phone).to(equal("0012345"))
                expect(distressMMSI).to(equal(987654321))
                expect(distressMMSINature).to(equal(.sinking))
                expect(acknowledgement).to(equal(.acknowledgement))
                expect(expansion).to(beFalse())
            }
        }
    }
}
