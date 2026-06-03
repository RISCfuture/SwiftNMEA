import Foundation
import Nimble
import NMEAUnits
import Quick

@testable import SwiftNMEA

final class XDRSpec: AsyncSpec {
  override static func spec() {
    describe("8.3.127 XDR") {
      func measurements(from fields: [Any?]) async throws -> [Transducer.Value] {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .waterLevelDetection,
          format: .transducerMeasurements,
          fields: fields
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)

        expect(messages).to(haveCount(2))
        guard let payload = (messages[1] as? Message)?.payload else {
          fail("expected Message, got \(messages[1])")
          return []
        }
        guard case .transducerMeasurements(let measurements) = payload else {
          fail("expected .transducerMeasurements, got \(payload)")
          return []
        }
        return measurements
      }

      func error(from fields: [Any?]) async throws -> MessageError? {
        let parser = SwiftNMEA()
        let sentence = createSentence(
          delimiter: .parametric,
          talker: .waterLevelDetection,
          format: .transducerMeasurements,
          fields: fields
        )
        let data = sentence.data(using: .ascii)!
        let messages = try await parser.parse(data: data)
        return messages.compactMap { $0 as? MessageError }.first
      }

      it("parses temperature in Celsius and Kelvin") {
        let measurements = try await measurements(from: [
          "C", 92.1, "C", "EngineOil#0",
          "C", 353.4, "K", "TransOil#0"
        ])
        expect(measurements).to(haveCount(2))
        expect(measurements[0]).to(
          equal(.temperature(.init(value: 92.1, unit: .celsius), id: "EngineOil#0"))
        )
        expect(measurements[1]).to(
          equal(.temperature(.init(value: 353.4, unit: .kelvin), id: "TransOil#0"))
        )
      }

      it("throws when a temperature uses Fahrenheit") {
        let error = try await error(from: ["C", 92.1, "F", "EngineOil#0"])
        expect(error?.type).to(equal(.badUnitValue))
      }

      it("parses a dew point") {
        let measurements = try await measurements(from: ["W", 12.3, "C", "Air#0"])
        expect(measurements).to(haveCount(1))
        expect(measurements[0]).to(
          equal(.dewPoint(.init(value: 12.3, unit: .celsius), id: "Air#0"))
        )
      }

      it("parses flow rate in litres/s and litres/h") {
        let measurements = try await measurements(from: [
          "R", 1.5, "L", "Fuel#0",
          "R", 90, "H", "Oil#0"
        ])
        expect(measurements).to(haveCount(2))
        expect(measurements[0]).to(
          equal(.flowRate(.init(value: 1.5, unit: .litersPerSecond), id: "Fuel#0"))
        )
        expect(measurements[1]).to(
          equal(.flowRate(.init(value: 90, unit: .litersPerHour), id: "Oil#0"))
        )
      }

      it("parses fluid level as cubic metres and as a percentage") {
        let measurements = try await measurements(from: [
          "E", 60, "P", "Fuel#1",
          "V", 12.5, "M", "BlackWater#0"
        ])
        expect(measurements).to(haveCount(2))
        expect(measurements[0]).to(equal(.fluidLevelPercent(60, id: "Fuel#1")))
        expect(measurements[1]).to(
          equal(.volume(.init(value: 12.5, unit: .cubicMeters), id: "BlackWater#0"))
        )
      }

      it("parses a switch as binary and a valve as a percentage") {
        let measurements = try await measurements(from: [
          "S", 1, "B", "Switch#1#4",
          "S", 0, "B", "Switch#0#2",
          "S", 10, "P", "Valve#2#0",
          "S", 100, "P", "Valve#321#1"
        ])
        expect(measurements).to(haveCount(4))
        expect(measurements[0]).to(equal(.boolean(true, id: "Switch#1#4")))
        expect(measurements[1]).to(equal(.boolean(false, id: "Switch#0#2")))
        expect(measurements[2]).to(equal(.switchValvePercent(10, id: "Valve#2#0")))
        expect(measurements[3]).to(equal(.switchValvePercent(100, id: "Valve#321#1")))
      }

      it("throws when a switch/valve uses an unrecognized unit") {
        let error = try await error(from: ["S", 1, "Q", "Switch#0#0"])
        expect(error?.type).to(equal(.badUnitValue))
      }

      it("throws when a volume uses an unrecognized unit") {
        let error = try await error(from: ["V", 12.5, "l", "Fuel#0"])
        expect(error?.type).to(equal(.badUnitValue))
      }

      it("parses a generic transducer") {
        let measurements = try await measurements(from: ["G", 23.4, nil, "SENSOR3"])
        expect(measurements).to(haveCount(1))
        expect(measurements[0]).to(equal(.generic(23.4, id: "SENSOR3")))
      }
    }
  }
}
