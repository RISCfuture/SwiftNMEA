import Foundation
import Testing

@testable import SwiftNMEA

@Suite("8.3.79 RMA")
struct RMATests {
  @Test("parses example (a) from the spec")
  func parsesExampleAFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,V,,,,,14162.8,,,,,,N*6F\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(!isValid)
    #expect(position == nil)
    #expect(timeDifferenceA == .init(value: 14162.8, unit: .microseconds))
    #expect(timeDifferenceB == nil)
    #expect(speed == nil)
    #expect(course == nil)
    #expect(magneticVariation == nil)
    #expect(mode == .invalid)
  }

  @Test("parses example (b) from the spec")
  func parsesExampleBFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,V,,,,,14172.3,26026.7,,,,,N*4C\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(!isValid)
    #expect(position == nil)
    #expect(timeDifferenceA == .init(value: 14172.3, unit: .microseconds))
    #expect(timeDifferenceB == .init(value: 26026.7, unit: .microseconds))
    #expect(speed == nil)
    #expect(course == nil)
    #expect(magneticVariation == nil)
    #expect(mode == .invalid)
  }

  @Test("parses example (c) from the spec")
  func parsesExampleCFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,A,,,,,14182.3,26026.7,,,,,A*5B\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(isValid)
    #expect(position == nil)
    #expect(timeDifferenceA == .init(value: 14182.3, unit: .microseconds))
    #expect(timeDifferenceB == .init(value: 26026.7, unit: .microseconds))
    #expect(speed == nil)
    #expect(course == nil)
    #expect(magneticVariation == nil)
    #expect(mode == .autonomous)
  }

  @Test("parses example (d) from the spec")
  func parsesExampleDFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,A,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,A*05\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(isValid)
    #expect(abs(position!.latitude.value - 42.4376666667) < 0.000001)
    #expect(abs(position!.longitude.value - -71.4315) < 0.000001)
    #expect(timeDifferenceA == .init(value: 14182.3, unit: .microseconds))
    #expect(timeDifferenceB == .init(value: 26026.7, unit: .microseconds))
    #expect(speed == .init(value: 8.5, unit: .knots))
    #expect(course!.angle == .init(value: 275, unit: .degrees))
    #expect(course!.reference == .true)
    #expect(magneticVariation == .init(value: -14, unit: .degrees))
    #expect(mode == .autonomous)
  }

  @Test("parses example (e) from the spec")
  func parsesExampleEFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,V,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,N*1D\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(!isValid)
    #expect(abs(position!.latitude.value - 42.4376666667) < 0.000001)
    #expect(abs(position!.longitude.value - -71.4315) < 0.000001)
    #expect(timeDifferenceA == .init(value: 14182.3, unit: .microseconds))
    #expect(timeDifferenceB == .init(value: 26026.7, unit: .microseconds))
    #expect(speed == .init(value: 8.5, unit: .knots))
    #expect(course!.angle == .init(value: 275, unit: .degrees))
    #expect(course!.reference == .true)
    #expect(magneticVariation == .init(value: -14, unit: .degrees))
    #expect(mode == .invalid)
  }

  @Test("parses example (f) from the spec")
  func parsesExampleFFromTheSpec() async throws {
    let parser = SwiftNMEA()
    let sentence = "$LCRMA,A,4226.265,N,07125.890,W,14172.33,26026.71,8.53,275.,14.0,W,D*3B\r\n"
    let data = sentence.data(using: .ascii)!
    let messages = try await parser.parse(data: data)

    #expect(messages.count == 2)
    let payload = try #require((messages[1] as? Message)?.payload)
    guard
      case let .LORANCMinimumData(
        isValid,
        position,
        timeDifferenceA,
        timeDifferenceB,
        speed,
        course,
        magneticVariation,
        mode
      ) = payload
    else {
      Issue.record("expected .LORANCMinimumData, got \(payload)")
      return
    }

    #expect(isValid)
    #expect(abs(position!.latitude.value - 42.43775) < 0.000001)
    #expect(abs(position!.longitude.value - -71.4315) < 0.000001)
    #expect(timeDifferenceA == .init(value: 14172.33, unit: .microseconds))
    #expect(timeDifferenceB == .init(value: 26026.71, unit: .microseconds))
    #expect(speed == .init(value: 8.53, unit: .knots))
    #expect(course!.angle == .init(value: 275, unit: .degrees))
    #expect(course!.reference == .true)
    #expect(magneticVariation == .init(value: -14, unit: .degrees))
    #expect(mode == .differential)
  }
}
