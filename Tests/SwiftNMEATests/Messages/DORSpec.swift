import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.27 DOR")
struct DORTests {
  @Test("parses the example from the spec")
  func parsesTheExampleFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentences = [
      applyChecksum(to: "$HDDOR,S,,FD,,,004,,,"),
      applyChecksum(to: "$HDDOR,E,,FD,CA,001,015,O,,A01015 Cabin 23"),
      applyChecksum(to: "$HDDOR,E,,FD,CA,001,032,O,,A01032 Locker 10"),
      applyChecksum(to: "$HDDOR,E,,FD,CB,002,026,O,,B02026 Cabin 34"),
      applyChecksum(to: "$HDDOR,E,,FD,CC,003,005,X,,C03005 Cabin 45")
    ]
    let data = sentences.joined().data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 10)

    let payload1 = try #require((messages[1] as? Message)?.payload)
    #expect(
      payload1
        == .doorStatus(
          messageType: .section,
          time: nil,
          systemType: .fire,
          division1: nil,
          division2: nil,
          doorNumber: 4,
          doorStatus: nil,
          switchSetting: nil,
          description: nil
        )
    )

    let payload3 = try #require((messages[3] as? Message)?.payload)
    #expect(
      payload3
        == .doorStatus(
          messageType: .event,
          time: nil,
          systemType: .fire,
          division1: "CA",
          division2: "001",
          doorNumber: 15,
          doorStatus: .open,
          switchSetting: nil,
          description: "A01015 Cabin 23"
        )
    )

    let payload5 = try #require((messages[5] as? Message)?.payload)
    #expect(
      payload5
        == .doorStatus(
          messageType: .event,
          time: nil,
          systemType: .fire,
          division1: "CA",
          division2: "001",
          doorNumber: 32,
          doorStatus: .open,
          switchSetting: nil,
          description: "A01032 Locker 10"
        )
    )

    let payload7 = try #require((messages[7] as? Message)?.payload)
    #expect(
      payload7
        == .doorStatus(
          messageType: .event,
          time: nil,
          systemType: .fire,
          division1: "CB",
          division2: "002",
          doorNumber: 26,
          doorStatus: .open,
          switchSetting: nil,
          description: "B02026 Cabin 34"
        )
    )

    let payload9 = try #require((messages[9] as? Message)?.payload)
    #expect(
      payload9
        == .doorStatus(
          messageType: .event,
          time: nil,
          systemType: .fire,
          division1: "CC",
          division2: "003",
          doorNumber: 5,
          doorStatus: .fault,
          switchSetting: nil,
          description: "C03005 Cabin 45"
        )
    )
  }
}
