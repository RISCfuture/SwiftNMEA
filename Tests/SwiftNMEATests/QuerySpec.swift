import Foundation
import Testing

@testable import SwiftNMEA

@Suite
struct `Query tests` {
  // MARK: - rawValue

  @Test
  func `encodes a sentence`() throws {
    let query = Query(
      requester: .GPS,
      recipient: .commDataReceiver,
      format: .MSKReceiverSignalStatus
    )
    #expect(query.rawValue == "$GPCRQ,MSS*36\r\n")
  }

  // MARK: - parsing

  @Test
  func `parses a sentence from a STA8089FG`() async throws {
    let parser = SwiftNMEA()
    // shortened to stay within the 82-character sentence limit
    let sentence =
      "$PSTMPVRAW,235943.070,9000.00000,N,00000.00000,E,0,00,0.0,-6356.31,M*33\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data, ignoreChecksums: true)

    #expect(messages.count == 1)
    let message = try #require(messages[0] as? ProprietarySentence)

    #expect(message.manufacturer == "STM")
    #expect(message.data == "PVRAW,235943.070,9000.00000,N,00000.00000,E,0,00,0.0,-6356.31,M")
  }

  @Test
  func `rejects an over-length proprietary sentence`() async throws {
    let parser = SwiftNMEA()
    let sentence =
      "$PSTMPVRAW,235943.070,9000.00000,N,00000.00000,E,0,00,0.0,-6356752.31,M,0.0,M,nan,nan,nan*33\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 1)
    let error = try #require(messages[0] as? MessageError)
    #expect(error.type == .sentenceTooLong)
  }
}
