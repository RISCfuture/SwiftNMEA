import Foundation
import NMEAUnits
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.127 XDR` {
  private func measurements(from fields: [String?]) throws -> [Transducer.Value] {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .transducerMeasurements,
      fields: fields
    )
    let data = sentence.data(using: .ascii)!
    let messages = try parser.parse(data: data)

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

  private func error(from fields: [String?]) throws -> MessageError? {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .waterLevelDetection,
      format: .transducerMeasurements,
      fields: fields
    )
    let data = sentence.data(using: .ascii)!
    let messages = try parser.parse(data: data)
    return messages.compactMap { $0 as? MessageError }.first
  }

  @Test(arguments: TransducerCase.all)
  func `parses transducer measurements`(_ testCase: TransducerCase) throws {
    let measurements = try measurements(from: testCase.fields)
    #expect(measurements == testCase.expected)
  }

  @Test(arguments: [
    ("a temperature in Fahrenheit", ["C", "92.1", "F", "EngineOil#0"]),
    ("a switch with an unrecognized unit", ["S", "1", "Q", "Switch#0#0"]),
    ("a volume with an unrecognized unit", ["V", "12.5", "l", "Fuel#0"])
  ])
  func `throws for an unrecognized unit`(_ name: String, _ fields: [String?]) throws {
    let error = try error(from: fields)
    #expect(error?.type == .badUnitValue, "\(name)")
  }

  /// One `XDR` sentence's transducer fields and the values they decode to.
  struct TransducerCase: Sendable, CustomTestStringConvertible {
    static let all: [Self] = [
      .init(
        name: "temperature in Celsius and Kelvin",
        fields: [
          "C", "92.1", "C", "EngineOil#0",
          "C", "353.4", "K", "TransOil#0"
        ],
        expected: [
          .temperature(.init(value: 92.1, unit: .celsius), id: "EngineOil#0"),
          .temperature(.init(value: 353.4, unit: .kelvin), id: "TransOil#0")
        ]
      ),
      .init(
        name: "a dew point",
        fields: ["W", "12.3", "C", "Air#0"],
        expected: [.dewPoint(.init(value: 12.3, unit: .celsius), id: "Air#0")]
      ),
      .init(
        name: "flow rate in litres/s and litres/h",
        fields: [
          "R", "1.5", "L", "Fuel#0",
          "R", "90", "H", "Oil#0"
        ],
        expected: [
          .flowRate(.init(value: 1.5, unit: .litersPerSecond), id: "Fuel#0"),
          .flowRate(.init(value: 90, unit: .litersPerHour), id: "Oil#0")
        ]
      ),
      .init(
        name: "fluid level as a percentage and volume in cubic metres",
        fields: [
          "E", "60", "P", "Fuel#1",
          "V", "12.5", "M", "BlackWater#0"
        ],
        expected: [
          .fluidLevelPercent(60, id: "Fuel#1"),
          .volume(.init(value: 12.5, unit: .cubicMeters), id: "BlackWater#0")
        ]
      ),
      .init(
        name: "a switch as binary and a valve as a percentage",
        fields: [
          "S", "1", "B", "Switch#1#4",
          "S", "0", "B", "Switch#0#2",
          "S", "10", "P", "Valve#2#0",
          "S", "100", "P", "Valve#321#1"
        ],
        expected: [
          .boolean(true, id: "Switch#1#4"),
          .boolean(false, id: "Switch#0#2"),
          .switchValvePercent(10, id: "Valve#2#0"),
          .switchValvePercent(100, id: "Valve#321#1")
        ]
      ),
      .init(
        name: "a generic transducer",
        fields: ["G", "23.4", nil, "SENSOR3"],
        expected: [.generic(23.4, id: "SENSOR3")]
      )
    ]

    let name: String
    let fields: [String?]
    let expected: [Transducer.Value]

    var testDescription: String { name }
  }
}
