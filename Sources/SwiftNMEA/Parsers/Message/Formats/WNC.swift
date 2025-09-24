import Collections
import Foundation
import NMEAUnits

class WNCParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .distanceWaypointToWaypoint
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let distanceNM = try sentence.fields.measurement(
      at: 0,
      valueType: .float,
      unitAt: 1,
      units: lengthUnits
    )!
    let distanceKM = try sentence.fields.measurement(
      at: 2,
      valueType: .float,
      unitAt: 3,
      units: lengthUnits
    )!
    let to = try sentence.fields.string(at: 4)!
    let from = try sentence.fields.string(at: 5)!

    return .distanceWaypointToWaypoint(
      distanceNM: distanceNM,
      distanceKM: distanceKM,
      to: to,
      from: from
    )
  }
}
