import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class FSISpec: AsyncSpec {
    override static func spec() {
        describe("8.3.31 FSI") {
            it("parses example (a) from the spec") {
                let parser = SwiftNMEA(),
                sentence = applyChecksum(to: "$CTFSI,020230,026140,m,0,C"),
                data = sentence.data(using: .ascii)!,
                messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF(frequency: .init(value: 2023, unit: .kilohertz))))
                expect(receive).to(equal(.MF_HF(frequency: .init(value: 2614, unit: .kilohertz))))
                expect(mode).to(equal(.J3E))
                expect(powerLevel).to(equal(0))
                expect(type).to(equal(.command))
            }

            it("parses example (b) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,020230,026140,m,5,R"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF(frequency: .init(value: 2023, unit: .kilohertz))))
                expect(receive).to(equal(.MF_HF(frequency: .init(value: 2614, unit: .kilohertz))))
                expect(mode).to(equal(.J3E))
                expect(powerLevel).to(equal(5))
                expect(type).to(equal(.reply))
            }

            it("parses example (c) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,,021820,o,,C"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(beNil())
                expect(receive).to(equal(.MF_HF(frequency: .init(value: 2182, unit: .kilohertz))))
                expect(mode).to(equal(.H3E))
                expect(powerLevel).to(beNil())
                expect(type).to(equal(.command))
            }

            it("parses the example (d) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CDFSI,900016,,d,9,R"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.VHF(mode: .standard, channel: 16)))
                expect(receive).to(beNil())
                expect(mode).to(equal(.F3E_G3E_simplex))
                expect(powerLevel).to(equal(9))
                expect(type).to(equal(.reply))
            }

            it("parses example (e) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,300821,,m,9,C"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF_telephone(channel: 821)))
                expect(receive).to(beNil())
                expect(mode).to(equal(.J3E))
                expect(powerLevel).to(equal(9))
                expect(type).to(equal(.command))
            }

            it("parses example (f) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,404001,,w,5,R"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF_teletype(band: 4, channel: 1)))
                expect(receive).to(beNil())
                expect(mode).to(equal(.F1B_J2B))
                expect(powerLevel).to(equal(5))
                expect(type).to(equal(.reply))
            }

            it("parses example (g) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,416193,,s,0,C"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF_teletype(band: 16, channel: 193)))
                expect(receive).to(beNil())
                expect(mode).to(equal(.F1B_J2B_ARQ_NBDP))
                expect(powerLevel).to(equal(0))
                expect(type).to(equal(.command))
            }

            it("parses example (h) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CTFSI,041620,043020,|,9,R"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(equal(.MF_HF(frequency: .init(value: 4162, unit: .kilohertz))))
                expect(receive).to(equal(.MF_HF(frequency: .init(value: 4302, unit: .kilohertz))))
                expect(mode).to(equal(.F1C_F2C_F3C))
                expect(powerLevel).to(equal(9))
                expect(type).to(equal(.reply))
            }

            it("parses example (i) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = applyChecksum(to: "$CXFSI,,021875,t,,C"),
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let message = messages[1] as? Message else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .frequencySetInfo(transmit, receive, mode, powerLevel, type) = message.payload else {
                    fail("expected .frequencySetInfo, got \(message)")
                    return
                }

                expect(transmit).to(beNil())
                expect(receive).to(equal(.MF_HF(frequency: .init(value: 2187.5, unit: .kilohertz))))
                expect(mode).to(equal(.F1B_J2B_receive))
                expect(powerLevel).to(beNil())
                expect(type).to(equal(.command))
            }
        }
    }
}
