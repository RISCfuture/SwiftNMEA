import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class NRMSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.62 NRM") {
      it("parses the first example sentence") {
        let parser = SwiftNMEA()
        let data = Data("$INNRM,2,1,00001E1F,00000023,R*29\r\n".utf8)
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .NAVTEXReceiverMask(
            let function,
            let frequency,
            let coverageAreaMask,
            let messageTypeMask,
            let status
          ) =
            payload
        else {
          fail("expected .windDirectionSpeed, got \(payload)")
          return
        }

        expect(function).to(equal(.printer))
        expect(frequency).to(equal(.freq490))
        for area in "ABCDEJKLM" {
          expect(coverageAreaMask![area]).to(beTrue())
        }
        for area in "FGHINOPQRSTUVWXYZ" {
          expect(coverageAreaMask![area]).to(beFalse())
        }
        for type in "ABF" {
          expect(messageTypeMask![type]).to(beTrue())
        }
        for type in "CDEGHIJKLMNOPQRSTUVWXYZ" {
          expect(messageTypeMask![type]).to(beFalse())
        }
        expect(status).to(equal(.reply))
      }

      it("parses the second example sentence") {
        let parser = SwiftNMEA()
        let data = Data("$INNRM,0,2,00001E1F,0FFFFFFF,R*5F\r\n".utf8)
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard
          case .NAVTEXReceiverMask(
            let function,
            let frequency,
            let coverageAreaMask,
            let messageTypeMask,
            let status
          ) =
            payload
        else {
          fail("expected .NAVTEXReceiverMask, got \(payload)")
          return
        }

        expect(function).to(equal(.request))
        expect(frequency).to(equal(.freq518))
        for area in "ABCDEJKLM" {
          expect(coverageAreaMask![area]).to(beTrue())
        }
        for area in "FGHINOPQRSTUVWXYZ" {
          expect(coverageAreaMask![area]).to(beFalse())
        }
        for type in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
          expect(messageTypeMask![type]).to(beTrue())
        }
        expect(status).to(equal(.reply))
      }
    }
  }
}
