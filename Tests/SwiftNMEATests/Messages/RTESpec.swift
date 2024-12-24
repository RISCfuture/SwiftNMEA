import Foundation
import Nimble
import Quick
@testable import SwiftNMEA

final class RTESpec: AsyncSpec {
    override static func spec() {
        describe("8.3.75 RTE") {
            describe(".parse") {
                it("parses a sentence") {

                    // MARK: Setup

                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .integratedNavigation, format: .route,
                                fields: [2, 1, "c", "KSQLKDWA",
                                         "KSQL", "DMDWW", "VPMID", "OAK30"]),
                            createSentence(
                                delimiter: .parametric, talker: .integratedNavigation, format: .route,
                                fields: [2, 2, nil, nil,
                                         "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"]),
                            createSentence(
                                delimiter: .parametric, talker: .integratedNavigation, format: .route,
                                fields: [1, 1, "w", "KSQLKOAK",
                                         "DMDWW", "VPMID", "OAKSLM", "KOAK"])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(5))

                    // MARK: Message 0

                    guard let payload = (messages[2] as? Message)?.payload else {
                        fail("expected Message, got \(messages[2])")
                        return
                    }
                    guard case let .route(mode, identifier, waypoints) = payload else {
                        fail("expected .route, got \(payload)")
                        return
                    }
                    expect(mode).to(equal(.complete))
                    expect(identifier).to(equal("KSQLKDWA"))
                    expect(waypoints).to(equal(["KSQL", "DMDWW", "VPMID", "OAK30",
                                                "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"]))

                    // MARK: Message 1

                    guard let payload = (messages[4] as? Message)?.payload else {
                        fail("expected Message, got \(messages[4])")
                        return
                    }
                    guard case let .route(mode, identifier, waypoints) = payload else {
                        fail("expected .route, got \(payload)")
                        return
                    }
                    expect(mode).to(equal(.working))
                    expect(identifier).to(equal("KSQLKOAK"))
                    expect(waypoints).to(equal(["DMDWW", "VPMID", "OAKSLM", "KOAK"]))
                }

                it("throws an error for an invalid senence number") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            createSentence(
                                delimiter: .parametric, talker: .integratedNavigation, format: .route,
                                fields: [2, 1, "c", "KSQLKDWA",
                                         "KSQL", "DMDWW", "VPMID", "OAK30"]),
                            createSentence(
                                delimiter: .parametric, talker: .integratedNavigation, format: .route,
                                fields: [2, 3, nil, nil,
                                         "OAKCO", "COLLI", "OAKEY", "EMBER", "TRIMM", "KDWA"])
                        ],
                        data = sentences.joined().data(using: .ascii)!,
                        messages = try await parser.parse(data: data)

                    expect(messages).to(haveCount(3))
                    guard let error = messages[2] as? MessageError else {
                        fail("expected MessageError, got \(messages[2])")
                        return
                    }
                        expect(error.type).to(equal(.wrongSentenceNumber))
                        expect(error.fieldNumber).to(equal(1))
                }
            }

            describe(".flush") {
                it("flushes incomplete sentences") {
                    let parser = SwiftNMEA(),
                        sentence = createSentence(
                            delimiter: .parametric, talker: .integratedNavigation, format: .route,
                            fields: [2, 1, "c", "KSQLKDWA",
                                     "KSQL", "DMDWW", "VPMID", "OAK30"]),
                        data = sentence.data(using: .ascii)!

                    let parsed = try await parser.parse(data: data)
                    expect(parsed).to(haveCount(1))

                    let messages = try await parser.flush(includeIncomplete: true)
                    expect(messages).to(haveCount(1))

                    guard let message = messages[0] as? Message else {
                        fail("expected Message, got \(messages[0])")
                        return
                    }
                    guard case let .route(mode, identifier, waypoints) = message.payload else {
                        fail("expected .route, got \(message)")
                        return
                    }
                    expect(mode).to(equal(.complete))
                    expect(identifier).to(equal("KSQLKDWA"))
                    expect(waypoints).to(equal(["KSQL", "DMDWW", "VPMID", "OAK30"]))
                }
            }
        }
    }
}
