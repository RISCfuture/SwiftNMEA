import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.75 OSD")
struct OSDTests {
  @Test("parses a sentence")
  func parsesASentence() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .ownshipData,
      fields: [
        5.0, "A",
        8.0, "B",
        12.5, "R",
        1.5, 2.1, "N"
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .ownshipData(
        heading,
        headingValid,
        course,
        courseReference,
        speed,
        speedReference,
        set,
        drift
      ) = payload
    else {
      Issue.record("expected .ownshipData, got \(payload)")
      return
    }

    #expect(heading?.angle == .init(value: 5, unit: .degrees))
    #expect(heading?.reference == .true)
    #expect(headingValid)
    #expect(course?.angle == .init(value: 8, unit: .degrees))
    #expect(course?.reference == .true)
    #expect(courseReference == .bottom)
    #expect(speed == .init(value: 12.5, unit: .knots))
    #expect(speedReference == .radar)
    #expect(set?.angle == .init(value: 1.5, unit: .degrees))
    #expect(set?.reference == .true)
    #expect(drift == .init(value: 2.1, unit: .knots))
  }

  @Test("parses a sentence with all data fields null")
  func parsesASentenceWithAllDataFieldsNull() async throws {
    let parser = SwiftNMEA()
    let sentence = createSentence(
      delimiter: .parametric,
      talker: .integratedNavigation,
      format: .ownshipData,
      fields: [
        nil, "V",
        nil, nil,
        nil, nil,
        nil, nil, nil
      ]
    )
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .ownshipData(
        heading,
        headingValid,
        course,
        courseReference,
        speed,
        speedReference,
        set,
        drift
      ) = payload
    else {
      Issue.record("expected .ownshipData, got \(payload)")
      return
    }

    #expect(heading == nil)
    #expect(!headingValid)
    #expect(course == nil)
    #expect(courseReference == nil)
    #expect(speed == nil)
    #expect(speedReference == nil)
    #expect(set == nil)
    #expect(drift == nil)
  }
}
