import Foundation
import NMEACommon
import Testing

@testable import SwiftNMEA

@Suite
struct `8.3.79 RMA` {
  @Test(arguments: SpecExample.all)
  func `parses an example from the spec`(_ example: SpecExample) throws {
    let parser = SwiftNMEA()
    let data = example.sentence.data(using: .ascii)!
    let messages = try parser.parse(data: data)

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

    #expect(isValid == example.isValid)
    if let latitude = example.latitude, let longitude = example.longitude {
      #expect(abs(position!.latitude.value - latitude) < 0.000001)
      #expect(abs(position!.longitude.value - longitude) < 0.000001)
    } else {
      #expect(position == nil)
    }
    #expect(timeDifferenceA == example.timeDifferenceA)
    #expect(timeDifferenceB == example.timeDifferenceB)
    #expect(speed == example.speed)
    #expect(course == example.course)
    #expect(magneticVariation == example.magneticVariation)
    #expect(mode == example.mode)
  }

  /// One of the lettered `RMA` examples from §8.3.79 of the spec.
  struct SpecExample: Sendable, CustomTestStringConvertible {
    private static let course275 = Bearing(degrees: 275, reference: .true)

    static let all: [Self] = [
      .init(
        letter: "a",
        sentence: "$LCRMA,V,,,,,14162.8,,,,,,N*6F\r\n",
        isValid: false,
        latitude: nil,
        longitude: nil,
        timeDifferenceA: .init(value: 14162.8, unit: .microseconds),
        timeDifferenceB: nil,
        speed: nil,
        course: nil,
        magneticVariation: nil,
        mode: .invalid
      ),
      .init(
        letter: "b",
        sentence: "$LCRMA,V,,,,,14172.3,26026.7,,,,,N*4C\r\n",
        isValid: false,
        latitude: nil,
        longitude: nil,
        timeDifferenceA: .init(value: 14172.3, unit: .microseconds),
        timeDifferenceB: .init(value: 26026.7, unit: .microseconds),
        speed: nil,
        course: nil,
        magneticVariation: nil,
        mode: .invalid
      ),
      .init(
        letter: "c",
        sentence: "$LCRMA,A,,,,,14182.3,26026.7,,,,,A*5B\r\n",
        isValid: true,
        latitude: nil,
        longitude: nil,
        timeDifferenceA: .init(value: 14182.3, unit: .microseconds),
        timeDifferenceB: .init(value: 26026.7, unit: .microseconds),
        speed: nil,
        course: nil,
        magneticVariation: nil,
        mode: .autonomous
      ),
      .init(
        letter: "d",
        sentence: "$LCRMA,A,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,A*05\r\n",
        isValid: true,
        latitude: 42.4376666667,
        longitude: -71.4315,
        timeDifferenceA: .init(value: 14182.3, unit: .microseconds),
        timeDifferenceB: .init(value: 26026.7, unit: .microseconds),
        speed: .init(value: 8.5, unit: .knots),
        course: course275,
        magneticVariation: .init(value: -14, unit: .degrees),
        mode: .autonomous
      ),
      .init(
        letter: "e",
        sentence: "$LCRMA,V,4226.26,N,07125.89,W,14182.3,26026.7,8.5,275.,14.0,W,N*1D\r\n",
        isValid: false,
        latitude: 42.4376666667,
        longitude: -71.4315,
        timeDifferenceA: .init(value: 14182.3, unit: .microseconds),
        timeDifferenceB: .init(value: 26026.7, unit: .microseconds),
        speed: .init(value: 8.5, unit: .knots),
        course: course275,
        magneticVariation: .init(value: -14, unit: .degrees),
        mode: .invalid
      ),
      .init(
        letter: "f",
        sentence: "$LCRMA,A,4226.265,N,07125.890,W,14172.33,26026.71,8.53,275.,14.0,W,D*3B\r\n",
        isValid: true,
        latitude: 42.43775,
        longitude: -71.4315,
        timeDifferenceA: .init(value: 14172.33, unit: .microseconds),
        timeDifferenceB: .init(value: 26026.71, unit: .microseconds),
        speed: .init(value: 8.53, unit: .knots),
        course: course275,
        magneticVariation: .init(value: -14, unit: .degrees),
        mode: .differential
      )
    ]

    let letter: Character
    let sentence: String
    let isValid: Bool
    let latitude: Double?
    let longitude: Double?
    let timeDifferenceA: Measurement<UnitDuration>?
    let timeDifferenceB: Measurement<UnitDuration>?
    let speed: Measurement<UnitSpeed>?
    let course: Bearing?
    let magneticVariation: Measurement<UnitAngle>?
    let mode: Navigation.Mode

    var testDescription: String { "example (\(letter))" }
  }
}
