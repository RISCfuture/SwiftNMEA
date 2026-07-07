import Foundation
import NMEAUnits
import Testing

@testable import SwiftNMEA

@Suite("8.3.127 XDR")
struct XDRTests {
  private func measurements(from fields: [Any?]) async throws -> [Transducer.Value] {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .transducerMeasurements,
      fields: fields
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    guard let payload = (messages[1] as? Message)?.payload else {
      Issue.record("expected Message, got \(messages[1])")
      return []
    }
    guard case .transducerMeasurements(let measurements) = payload else {
      Issue.record("expected .transducerMeasurements, got \(payload)")
      return []
    }
    return measurements
  }

  private func error(from fields: [Any?]) async throws -> MessageError? {
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

  @Test("parses temperature in Celsius and Kelvin")
  func parsesTemperatureInCelsiusAndKelvin() async throws {
    let measurements = try await measurements(from: [
      "C", 92.1, "C", "EngineOil#0",
      "C", 353.4, "K", "TransOil#0"
    ])
    #expect(measurements.count == 2)
    #expect(measurements[0] == .temperature(.init(value: 92.1, unit: .celsius), id: "EngineOil#0"))
    #expect(measurements[1] == .temperature(.init(value: 353.4, unit: .kelvin), id: "TransOil#0"))
  }

  @Test("throws when a temperature uses Fahrenheit")
  func throwsWhenATemperatureUsesFahrenheit() async throws {
    let error = try await error(from: ["C", 92.1, "F", "EngineOil#0"])
    #expect(error?.type == .badUnitValue)
  }

  @Test("parses a dew point")
  func parsesADewPoint() async throws {
    let measurements = try await measurements(from: ["W", 12.3, "C", "Air#0"])
    #expect(measurements.count == 1)
    #expect(measurements[0] == .dewPoint(.init(value: 12.3, unit: .celsius), id: "Air#0"))
  }

  @Test("parses flow rate in litres/s and litres/h")
  func parsesFlowRateInLitresSAndLitresH() async throws {
    let measurements = try await measurements(from: [
      "R", 1.5, "L", "Fuel#0",
      "R", 90, "H", "Oil#0"
    ])
    #expect(measurements.count == 2)
    #expect(measurements[0] == .flowRate(.init(value: 1.5, unit: .litersPerSecond), id: "Fuel#0"))
    #expect(measurements[1] == .flowRate(.init(value: 90, unit: .litersPerHour), id: "Oil#0"))
  }

  @Test("parses fluid level as cubic metres and as a percentage")
  func parsesFluidLevelAsCubicMetresAndAsAPercentage() async throws {
    let measurements = try await measurements(from: [
      "E", 60, "P", "Fuel#1",
      "V", 12.5, "M", "BlackWater#0"
    ])
    #expect(measurements.count == 2)
    #expect(measurements[0] == .fluidLevelPercent(60, id: "Fuel#1"))
    #expect(measurements[1] == .volume(.init(value: 12.5, unit: .cubicMeters), id: "BlackWater#0"))
  }

  @Test("parses a switch as binary and a valve as a percentage")
  func parsesASwitchAsBinaryAndAValveAsAPercentage() async throws {
    let measurements = try await measurements(from: [
      "S", 1, "B", "Switch#1#4",
      "S", 0, "B", "Switch#0#2",
      "S", 10, "P", "Valve#2#0",
      "S", 100, "P", "Valve#321#1"
    ])
    #expect(measurements.count == 4)
    #expect(measurements[0] == .boolean(true, id: "Switch#1#4"))
    #expect(measurements[1] == .boolean(false, id: "Switch#0#2"))
    #expect(measurements[2] == .switchValvePercent(10, id: "Valve#2#0"))
    #expect(measurements[3] == .switchValvePercent(100, id: "Valve#321#1"))
  }

  @Test("throws when a switch/valve uses an unrecognized unit")
  func throwsWhenASwitchValveUsesAnUnrecognizedUnit() async throws {
    let error = try await error(from: ["S", 1, "Q", "Switch#0#0"])
    #expect(error?.type == .badUnitValue)
  }

  @Test("throws when a volume uses an unrecognized unit")
  func throwsWhenAVolumeUsesAnUnrecognizedUnit() async throws {
    let error = try await error(from: ["V", 12.5, "l", "Fuel#0"])
    #expect(error?.type == .badUnitValue)
  }

  @Test("parses a generic transducer")
  func parsesAGenericTransducer() async throws {
    let measurements = try await measurements(from: ["G", 23.4, nil, "SENSOR3"])
    #expect(measurements.count == 1)
    #expect(measurements[0] == .generic(23.4, id: "SENSOR3"))
  }
}
