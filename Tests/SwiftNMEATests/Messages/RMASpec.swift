import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RMASpec: AsyncSpec {
    override static func spec() {
        describe("8.3.67 RMA") {
            it("parses example (a) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,V,,,,,14162.8,,,,,,N*6F\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beFalse())
                expect(position).to(beNil())
                expect(timeDifferenceA).to(equal(.init(value: 14162.8, unit: .microseconds)))
                expect(timeDifferenceB).to(beNil())
                expect(speed).to(beNil())
                expect(course).to(beNil())
                expect(magneticVariation).to(beNil())
                expect(mode).to(equal(.invalid))
            }

            it("parses example (b) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,V,,,,,14172.3,26026.7,,,,,N*4C\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beFalse())
                expect(position).to(beNil())
                expect(timeDifferenceA).to(equal(.init(value: 14172.3, unit: .microseconds)))
                expect(timeDifferenceB).to(equal(.init(value: 26026.7, unit: .microseconds)))
                expect(speed).to(beNil())
                expect(course).to(beNil())
                expect(magneticVariation).to(beNil())
                expect(mode).to(equal(.invalid))
            }

            it("parses example (c) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,A,,,,,14182.3,26026.7,,,,,A*5B\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beTrue())
                expect(position).to(beNil())
                expect(timeDifferenceA).to(equal(.init(value: 14182.3, unit: .microseconds)))
                expect(timeDifferenceB).to(equal(.init(value: 26026.7, unit: .microseconds)))
                expect(speed).to(beNil())
                expect(course).to(beNil())
                expect(magneticVariation).to(beNil())
                expect(mode).to(equal(.autonomous))
            }

            it("parses example (d) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,A,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,A*05\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beTrue())
                expect(position!.latitude.value).to(beCloseTo(42.4376666667, within: 0.000001))
                expect(position!.longitude.value).to(beCloseTo(-71.4315, within: 0.000001))
                expect(timeDifferenceA).to(equal(.init(value: 14182.3, unit: .microseconds)))
                expect(timeDifferenceB).to(equal(.init(value: 26026.7, unit: .microseconds)))
                expect(speed).to(equal(.init(value: 8.5, unit: .knots)))
                expect(course!.angle).to(equal(.init(value: 275, unit: .degrees)))
                expect(course!.reference).to(equal(.true))
                expect(magneticVariation).to(equal(.init(value: -14, unit: .degrees)))
                expect(mode).to(equal(.autonomous))
            }

            it("parses example (e) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,V,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,N*1D\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beFalse())
                expect(position!.latitude.value).to(beCloseTo(42.4376666667, within: 0.000001))
                expect(position!.longitude.value).to(beCloseTo(-71.4315, within: 0.000001))
                expect(timeDifferenceA).to(equal(.init(value: 14182.3, unit: .microseconds)))
                expect(timeDifferenceB).to(equal(.init(value: 26026.7, unit: .microseconds)))
                expect(speed).to(equal(.init(value: 8.5, unit: .knots)))
                expect(course!.angle).to(equal(.init(value: 275, unit: .degrees)))
                expect(course!.reference).to(equal(.true))
                expect(magneticVariation).to(equal(.init(value: -14, unit: .degrees)))
                expect(mode).to(equal(.invalid))
            }

            it("parses example (f) from the spec") {
                let parser = SwiftNMEA(),
                    sentence = "$LCRMA,A,4226.265,N,07125.890,W,14172.33,26026.71,8.53,275.,14.0,W,D*3B\r\n",
                    data = sentence.data(using: .ascii)!,
                    messages = try await parser.parse(data: data)

                expect(messages).to(haveCount(2))
                guard let payload = (messages[1] as? Message)?.payload else {
                    fail("expected Message, got \(messages[1])")
                    return
                }
                guard case let .LORANCMinimumData(isValid, position, timeDifferenceA, timeDifferenceB, speed, course, magneticVariation, mode) = payload else {
                    fail("expected .LORANCMinimumData, got \(payload)")
                    return
                }

                expect(isValid).to(beTrue())
                expect(position!.latitude.value).to(beCloseTo(42.43775, within: 0.000001))
                expect(position!.longitude.value).to(beCloseTo(-71.4315, within: 0.000001))
                expect(timeDifferenceA).to(equal(.init(value: 14172.33, unit: .microseconds)))
                expect(timeDifferenceB).to(equal(.init(value: 26026.71, unit: .microseconds)))
                expect(speed).to(equal(.init(value: 8.53, unit: .knots)))
                expect(course!.angle).to(equal(.init(value: 275, unit: .degrees)))
                expect(course!.reference).to(equal(.true))
                expect(magneticVariation).to(equal(.init(value: -14, unit: .degrees)))
                expect(mode).to(equal(.differential))
            }
        }
    }
}
