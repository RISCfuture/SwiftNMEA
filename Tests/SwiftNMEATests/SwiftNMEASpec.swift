import Algorithms
import Nimble
import Quick
@testable import SwiftNMEA

final class NMEASpec: AsyncSpec {
    override static func spec() {
        describe("SwiftNMEA") {
            describe(".parse") {
                it("handles chunked data") {
                    let parser = SwiftNMEA(),
                        sentences = [
                            "$GPAAM,A,V,0.5,N,KSFO*15\r\n",
                            "$GPAAM,V,A,0.1,N,KLAX*1E\r\n",
                            "$GPAAM,V,V,0.2,N,KABC*1F\r\n"
                        ].joined(),
                        data = sentences.data(using: .ascii)!,
                        chunks = data.chunks(ofCount: 5)

                    var messages = [any Element]()
                    for chunk in chunks {
                        try await messages.append(contentsOf: parser.parse(data: chunk))
                    }

                    expect(messages).to(haveCount(6))
                }

                context("filters") {
                    let sentences = [
                        applyChecksum(to: "$GPAAM,A,V,0.5,N,KSFO"),
                        applyChecksum(to: "$INNRM,2,1,00001E1F,00000023,C"),
                        applyChecksum(to: "$GPCRQ,MSK"),
                        applyChecksum(to: "$INCRQ,AAM"),
                        "$GPAAM,A,V,0.5,N,KSFO*AA\r\n",
                        applyChecksum(to: "$PSRDA003[470738][1224523]???RST47, 3809, A004 ")
                    ],
                        data = sentences.joined().data(using: .ascii)!

                    context("filtering by message type") {
                        it("filters in all messages with empty filters") {
                            let parser = SwiftNMEA(),
                                messages = try await parser.parse(data: data)
                            expect(messages).to(haveCount(8))
                            expect(messages.filter { $0 is ParametricSentence }).to(haveCount(2))
                            expect(messages.filter { $0 is Query }).to(haveCount(2))
                            expect(messages.filter { $0 is ProprietarySentence }).to(haveCount(1))
                            expect(messages.filter { $0 is Message }).to(haveCount(2))
                            expect(messages.filter { $0 is MessageError }).to(haveCount(1))
                        }

                        it("filters parametric sentences") {
                            let parser = SwiftNMEA(typeFilter: [ParametricSentence.self]),
                                messages = try await parser.parse(data: data)
                            expect(messages).to(haveCount(3))
                            expect(messages.filter { $0 is ParametricSentence }).to(haveCount(2))
                            expect(messages.filter { $0 is MessageError }).to(haveCount(1))
                        }

                        it("filters queries") {
                            let parser = SwiftNMEA(typeFilter: [Query.self]),
                                messages = try await parser.parse(data: data)
                            expect(messages).to(haveCount(2))
                            expect(messages).to(allPass(beAKindOf(Query.self)))
                        }

                        it("filters proprietary sentences") {
                            let parser = SwiftNMEA(typeFilter: [ProprietarySentence.self]),
                                messages = try await parser.parse(data: data)
                            expect(messages).to(haveCount(1))
                            expect(messages).to(allPass(beAKindOf(ProprietarySentence.self)))
                        }

                        it("filters messages") {
                            let parser = SwiftNMEA(typeFilter: [Message.self]),
                                messages = try await parser.parse(data: data)
                            expect(messages).to(haveCount(3))
                            expect(messages.filter { $0 is Message }).to(haveCount(2))
                            expect(messages.filter { $0 is MessageError }).to(haveCount(1))
                        }
                    }

                    it("filters by talker") {
                        let parser = SwiftNMEA(talkerFilter: [.GPS]),
                            messages = try await parser.parse(data: data)

                        expect(messages).to(haveCount(4))
                        expect(messages).to(allPass { message in
                            if let message = message as? Query { message.requester == .GPS }
                            else if let message = message as? ParametricSentence { message.talker == .GPS }
                            else if let message = message as? Message { message.talker == .GPS }
                            else if message is MessageError { true }
                            else { false }
                        })
                    }

                    it("filters by format") {
                        let parser = SwiftNMEA(formatFilter: [.waypointArrivalAlarm]),
                            messages = try await parser.parse(data: data)

                        expect(messages).to(haveCount(4))
                        expect(messages).to(allPass { message in
                            if let message = message as? Query { message.format == .waypointArrivalAlarm }
                            else if let message = message as? ParametricSentence { message.format == .waypointArrivalAlarm }
                            else if let message = message as? Message { message.format == .waypointArrivalAlarm }
                            else if message is MessageError { true }
                            else { false }
                        })
                    }
                }

                context("checksums") {
                    it("rejects an invalid checksum") {
                        let parser = SwiftNMEA(),
                            data = "$GPAAM,A,V,0.5,N,KSFO*AA\r\n".data(using: .ascii)!,
                            messages = try await parser.parse(data: data)

                        expect(messages).to(haveCount(1))
                        guard let error = messages[0] as? MessageError else {
                            fail("expected MessageError, got \(messages[0])")
                            return
                        }
                        expect(error.type).to(equal(.wrongChecksum))
                    }

                    it("ignores an invalid checksum when ignoreChecksums is true") {
                        let parser = SwiftNMEA(),
                            data = "$GPAAM,A,V,0.5,N,KSFO*AA\r\n".data(using: .ascii)!

                        expect { try await parser.parse(data: data, ignoreChecksums: true) }.notTo(throwError())
                    }
                }

                context("queries") {
                    it("parses a query") {
                        let parser = SwiftNMEA(),
                            data = "$GPCRQ,MSK*2E\r\n".data(using: .ascii)!

                        var messages = [any Element]()
                        try await messages.append(contentsOf: parser.parse(data: data))

                        expect(messages).to(haveCount(1))
                        guard let query = messages[0] as? Query else {
                            fail("expected Query, got \(messages[0])")
                            return
                        }
                        expect(query.requester).to(equal(.GPS))
                        expect(query.recipient).to(equal(.commDataReceiver))
                        expect(query.format).to(equal(.MSKReceiverInterface))
                    }
                }

                context("proprietary messages") {
                    it("parses a proprietary message") {
                        let parser = SwiftNMEA(),
                            data = "$PSRDA003[470738][1224523]???RST47, 3809, A004*47\r\n".data(using: .ascii)!

                        var messages = [any Element]()
                        try await messages.append(contentsOf: parser.parse(data: data))

                        expect(messages).to(haveCount(1))
                        guard let query = messages[0] as? ProprietarySentence else {
                            fail("expected ProprietaryMessage, got \(messages[0])")
                            return
                        }
                        expect(query.manufacturer).to(equal("SRD"))
                        expect(query.data).to(equal("A003[470738][1224523]???RST47, 3809, A004"))
                    }
                }
            }
        }
    }
}
