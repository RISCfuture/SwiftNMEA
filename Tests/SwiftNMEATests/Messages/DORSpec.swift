import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class DORSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.23 DOR") {
      it("parses the example from the spec") {
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

        expect(messages).to(haveCount(10))

        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        expect(payload).to(
          equal(
            .doorStatus(
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
        )

        guard let payload = (messages[3] as? Message)?.payload else {
          fail("expected Message, got \(messages[3])")
          return
        }
        expect(payload).to(
          equal(
            .doorStatus(
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
        )

        guard let payload = (messages[5] as? Message)?.payload else {
          fail("expected Message, got \(messages[5])")
          return
        }
        expect(payload).to(
          equal(
            .doorStatus(
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
        )

        guard let payload = (messages[7] as? Message)?.payload else {
          fail("expected Message, got \(messages[7])")
          return
        }
        expect(payload).to(
          equal(
            .doorStatus(
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
        )

        guard let payload = (messages[9] as? Message)?.payload else {
          fail("expected Message, got \(messages[9])")
          return
        }
        expect(payload).to(
          equal(
            .doorStatus(
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
        )
      }
    }
  }
}
