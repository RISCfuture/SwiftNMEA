import Algorithms
import Foundation
import Testing

@testable import SwiftNMEA

@Suite("SwiftNMEA")
struct NMEATests {
  private static let filterData: Data = {
    let sentences = [
      applyChecksum(to: "$GPAAM,A,V,0.5,N,KSFO"),
      applyChecksum(to: "$INNRM,2,1,00001E1F,00000023,C"),
      applyChecksum(to: "$GPCRQ,MSK"),
      applyChecksum(to: "$INCRQ,AAM"),
      "$GPAAM,A,V,0.5,N,KSFO*AA\r\n",
      applyChecksum(to: "$PSRDA003[470738][1224523]???RST47, 3809, A004 ")
    ]
    return sentences.joined().data(using: .ascii)!
  }()

  // MARK: - .parse

  @Test("handles chunked data")
  func handlesChunkedData() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      "$GPAAM,A,V,0.5,N,KSFO*15\r\n",
      "$GPAAM,V,A,0.1,N,KLAX*1E\r\n",
      "$GPAAM,V,V,0.2,N,KABC*1F\r\n"
    ].joined()
    let data = sentences.data(using: .ascii)!
    let chunks = data.chunks(ofCount: 5)

    var messages = [any Element]()
    for chunk in chunks {
      try await messages.append(contentsOf: parser.parse(data: chunk))
    }

    #expect(messages.count == 6)
  }

  // MARK: filtering by message type

  @Test("filters in all messages with empty filters")
  func filtersInAllMessagesWithEmptyFilters()
    async throws
  {
    let parser = SwiftNMEA()
    let messages = try await parser.parse(data: Self.filterData)
    #expect(messages.count == 8)
    #expect(messages.filter { $0 is ParametricSentence }.count == 2)
    #expect(messages.filter { $0 is Query }.count == 2)
    #expect(messages.filter { $0 is ProprietarySentence }.count == 1)
    #expect(messages.filter { $0 is Message }.count == 2)
    #expect(messages.filter { $0 is MessageError }.count == 1)
  }

  @Test("filters parametric sentences")
  func filtersParametricSentences() async throws {
    let parser = SwiftNMEA(typeFilter: [ParametricSentence.self])
    let messages = try await parser.parse(data: Self.filterData)
    #expect(messages.count == 3)
    #expect(messages.filter { $0 is ParametricSentence }.count == 2)
    #expect(messages.filter { $0 is MessageError }.count == 1)
  }

  @Test("filters queries")
  func filtersQueries() async throws {
    let parser = SwiftNMEA(typeFilter: [Query.self])
    let messages = try await parser.parse(data: Self.filterData)
    #expect(messages.count == 2)
    #expect(messages.allSatisfy { $0 is Query })
  }

  @Test("filters proprietary sentences")
  func filtersProprietarySentences() async throws {
    let parser = SwiftNMEA(typeFilter: [ProprietarySentence.self])
    let messages = try await parser.parse(data: Self.filterData)
    #expect(messages.count == 1)
    #expect(messages.allSatisfy { $0 is ProprietarySentence })
  }

  @Test("filters messages")
  func filtersMessages() async throws {
    let parser = SwiftNMEA(typeFilter: [Message.self])
    let messages = try await parser.parse(data: Self.filterData)
    #expect(messages.count == 3)
    #expect(messages.filter { $0 is Message }.count == 2)
    #expect(messages.filter { $0 is MessageError }.count == 1)
  }

  @Test("filters by talker")
  func filtersByTalker() async throws {
    let parser = SwiftNMEA(talkerFilter: [.GPS])
    let messages = try await parser.parse(data: Self.filterData)

    #expect(messages.count == 4)
    #expect(
      messages.allSatisfy { message in
        if let message = message as? Query {
          message.requester == .GPS
        } else if let message = message as? ParametricSentence {
          message.talker == .GPS
        } else if let message = message as? Message {
          message.talker == .GPS
        } else if message is MessageError {
          true
        } else {
          false
        }
      }
    )
  }

  @Test("filters by format")
  func filtersByFormat() async throws {
    let parser = SwiftNMEA(formatFilter: [.waypointArrivalAlarm])
    let messages = try await parser.parse(data: Self.filterData)

    #expect(messages.count == 4)
    #expect(
      messages.allSatisfy { message in
        if let message = message as? Query {
          message.format == .waypointArrivalAlarm
        } else if let message = message as? ParametricSentence {
          message.format == .waypointArrivalAlarm
        } else if let message = message as? Message {
          message.format == .waypointArrivalAlarm
        } else if message is MessageError {
          true
        } else {
          false
        }
      }
    )
  }

  // MARK: checksums

  @Test("rejects an invalid checksum")
  func rejectsAnInvalidChecksum() async throws {
    let parser = SwiftNMEA()
    let data = "$GPAAM,A,V,0.5,N,KSFO*AA\r\n".data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 1)
    let error = try #require(messages[0] as? MessageError)
    #expect(error.type == .wrongChecksum)
  }

  @Test("ignores an invalid checksum when ignoreChecksums is true")
  func ignoresAnInvalidChecksumWhenIgnoreChecksumsIsTrue() async throws {
    let parser = SwiftNMEA()
    let data = "$GPAAM,A,V,0.5,N,KSFO*AA\r\n".data(using: .ascii)!

    await #expect(throws: Never.self) { try await parser.parse(data: data, ignoreChecksums: true) }
  }

  // MARK: queries

  @Test("parses a query")
  func parsesAQuery() async throws {
    let parser = SwiftNMEA()
    let data = "$GPCRQ,MSK*2E\r\n".data(using: .ascii)!

    var messages = [any Element]()
    try await messages.append(contentsOf: parser.parse(data: data))

    #expect(messages.count == 1)
    let query = try #require(messages[0] as? Query)
    #expect(query.requester == .GPS)
    #expect(query.recipient == .commDataReceiver)
    #expect(query.format == .MSKReceiverInterface)
  }

  // MARK: proprietary messages

  @Test("parses a proprietary message")
  func parsesAProprietaryMessage() async throws {
    let parser = SwiftNMEA()
    let data = "$PSRDA003[470738][1224523]???RST47, 3809, A004*47\r\n".data(using: .ascii)!

    var messages = [any Element]()
    try await messages.append(contentsOf: parser.parse(data: data))

    #expect(messages.count == 1)
    let query = try #require(messages[0] as? ProprietarySentence)
    #expect(query.manufacturer == "SRD")
    #expect(query.data == "A003[470738][1224523]???RST47, 3809, A004")
  }

  // MARK: malformed sentences

  @Test("surfaces a sentence-like garbage line as an unknownSentenceType error")
  func surfacesGarbageLineAsUnknownSentenceType() async throws {
    let parser = SwiftNMEA()
    let data = "$not a real sentence\r\n".data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 1)
    let error = try #require(messages[0] as? MessageError)
    #expect(error.type == .unknownSentenceType)
  }

  @Test("surfaces an over-long sentence-like line as a sentenceTooLong error")
  func surfacesOverLongLineAsSentenceTooLong() async throws {
    let parser = SwiftNMEA()
    let longField = String(repeating: "K", count: 90)
    let data = "$GPAAM,A,V,0.5,N,\(longField)*15\r\n".data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 1)
    let error = try #require(messages[0] as? MessageError)
    #expect(error.type == .sentenceTooLong)
  }

  @Test("silently drops a non-sentence-like noise line")
  func silentlyDropsNoiseLine()
    async throws
  {
    let parser = SwiftNMEA()
    let data = "\\s:foo,c:1234*hh\\\r\n".data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.isEmpty)
  }

  @Test("still parses a valid sentence")
  func stillParsesAValidSentence() async throws {
    let parser = SwiftNMEA()
    let data = "$GPAAM,A,V,0.5,N,KSFO*15\r\n".data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.filter { $0 is ParametricSentence }.count == 1)
    #expect(!messages.contains { $0 is MessageError })
  }
}
