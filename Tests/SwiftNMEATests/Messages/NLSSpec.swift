import Foundation
import Nimble
import Quick

@testable import SwiftNMEA

final class NLSSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.71 NLS") {
      it("parses a single-sentence message") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .navLightController,
          format: .navigationLightStatus,
          fields: [
            1, 1, 96, 2,
            12, 2, 27,
            3, 1, nil
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .navigationLightStatus(id, lights) = payload else {
          fail("expected .navigationLightStatus, got \(payload)")
          return
        }

        expect(id).to(equal(96))
        expect(lights).to(haveCount(2))
        expect(lights[0].identifier).to(equal(12))
        expect(lights[0].status).to(equal(.on))
        expect(lights[0].remainingWorkingHours)
          .to(equal(.estimate(.init(value: 2_700, unit: .hours))))
        expect(lights[1].identifier).to(equal(3))
        expect(lights[1].status).to(equal(.off))
        expect(lights[1].remainingWorkingHours).to(beNil())
      }

      it("parses a multi-sentence message") {
        let parser = SwiftNMEA()
        let sentences = [
          createSentence(
            delimiter: .parametric,
            talker: .navLightController,
            format: .navigationLightStatus,
            fields: [
              2, 1, 96, 4,
              12, 2, nil,
              3, 1, nil,
              471, 3, 4,
              6, 3, nil
            ]
          ),
          createSentence(
            delimiter: .parametric,
            talker: .navLightController,
            format: .navigationLightStatus,
            fields: [
              2, 2, 96, 2,
              2, 2, nil,
              33, 2, nil
            ]
          )
        ]
        let data = sentences.joined().data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        // two echoed sentences, one completed Message after the second
        expect(messages).to(haveCount(3))
        guard let payload = (messages[2] as? Message)?.payload else {
          fail("expected Message, got \(messages[2])")
          return
        }
        guard case let .navigationLightStatus(id, lights) = payload else {
          fail("expected .navigationLightStatus, got \(payload)")
          return
        }

        expect(id).to(equal(96))
        expect(lights).to(haveCount(6))
        expect(lights.map(\.identifier)).to(equal([12, 3, 471, 6, 2, 33]))
        expect(lights[2].remainingWorkingHours)
          .to(equal(.estimate(.init(value: 400, unit: .hours))))
        expect(lights[5].status).to(equal(.on))
      }

      it("parses unavailable status and remaining hours as nil") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .navLightController,
          format: .navigationLightStatus,
          fields: [
            1, 1, 0, 1,
            5, nil, nil
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return
        }
        guard case let .navigationLightStatus(_, lights) = payload else {
          fail("expected .navigationLightStatus, got \(payload)")
          return
        }

        expect(lights).to(haveCount(1))
        expect(lights[0].identifier).to(equal(5))
        expect(lights[0].status).to(beNil())
        expect(lights[0].remainingWorkingHours).to(beNil())
      }

      it("represents more than 9 800 remaining hours") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .navLightController,
          format: .navigationLightStatus,
          fields: [
            1, 1, 1, 1,
            7, 2, 99
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let payload = (messages[1] as? Message)?.payload,
          case let .navigationLightStatus(_, lights) = payload
        else {
          fail("expected .navigationLightStatus, got \(messages[1])")
          return
        }
        expect(lights[0].remainingWorkingHours).to(equal(.moreThan9800Hours))
      }

      it("throws an error for an unknown light status") {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .navLightController,
          format: .navigationLightStatus,
          fields: [
            1, 1, 1, 1,
            8, 7, nil
          ]
        )
        let messages = try await parser.parse(data: sentence.data(using: .ascii)!)

        guard let error = messages[1] as? MessageError else {
          fail("expected MessageError, got \(messages[1])")
          return
        }
        expect(error.type).to(equal(.unknownValue))
      }
    }
  }
}
